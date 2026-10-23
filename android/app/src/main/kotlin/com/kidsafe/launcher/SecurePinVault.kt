package com.kidsafe.launcher

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import java.io.File
import java.io.IOException
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** Small native boundary needed for durable retry-state writes.
 * AtomicFile.finishWrite syncs the encrypted file before acknowledging success.
 * The key stays in Android Keystore; no keys or raw PINs cross this API.
 */
class SecurePinVault(context: Context) {
    private val alias = "kidsafe.pin.v1"
    private val base = File(context.noBackupFilesDir, "pin-vault.v1")
    private val file = AtomicFile(base)
    private val aad = "${context.packageName}:pin-vault:v1".toByteArray(Charsets.UTF_8)
    private val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

    private fun key(create: Boolean): SecretKey {
        if (store.containsAlias(alias)) {
            return store.getKey(alias, null) as? SecretKey ?: throw IOException("Key unavailable")
        }
        if (!create) throw IOException("Key unavailable")
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
            init(KeyGenParameterSpec.Builder(alias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setKeySize(256)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build())
        }.generateKey()
    }

    @Synchronized
    fun read(): String? {
        if (!base.exists() && !File(base.path + ".bak").exists()) {
            // A surviving key with missing data is not a fresh installation.
            if (store.containsAlias(alias)) throw IOException("Vault data missing")
            return null
        }
        val bytes = file.readFully()
        if (bytes.size !in 30..65536 || bytes[0] != 1.toByte()) {
            throw IOException("Invalid vault format")
        }
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(false), GCMParameterSpec(128, bytes.copyOfRange(1, 13)))
        cipher.updateAAD(aad)
        return cipher.doFinal(bytes.copyOfRange(13, bytes.size)).toString(Charsets.UTF_8)
    }

    @Synchronized
    fun write(value: String) {
        val plain = value.toByteArray(Charsets.UTF_8)
        if (plain.size > 60000) throw IOException("Vault record too large")
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key(true))
        cipher.updateAAD(aad)
        val iv = cipher.iv
        if (iv.size != 12) throw IOException("Unexpected GCM nonce size")
        val encrypted = byteArrayOf(1) + iv + cipher.doFinal(plain)
        val output = file.startWrite()
        try {
            output.write(encrypted)
            // Explicit sync propagates disk errors; AtomicFile also syncs during
            // finishWrite and handles restoration of interrupted transactions.
            output.fd.sync()
            file.finishWrite(output)
            if (!file.readFully().contentEquals(encrypted)) {
                throw IOException("Vault commit failed")
            }
        } catch (e: Exception) {
            file.failWrite(output)
            throw e
        }
    }
}
