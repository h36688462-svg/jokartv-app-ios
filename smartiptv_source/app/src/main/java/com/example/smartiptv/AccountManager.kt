package com.example.smartiptv

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

data class UserAccount(
    val name: String,
    val url: String,
    val username: String,
    val password: String
)

object AccountManager {
    private const val PREF_NAME = "accounts_prefs"
    private const val KEY_ACCOUNTS = "saved_accounts"

    fun getAccounts(context: Context): List<UserAccount> {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val jsonStr = prefs.getString(KEY_ACCOUNTS, "[]") ?: "[]"
        val array = JSONArray(jsonStr)
        val list = mutableListOf<UserAccount>()
        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            list.add(
                UserAccount(
                    obj.optString("name"),
                    obj.optString("url"),
                    obj.optString("username"),
                    obj.optString("password")
                )
            )
        }
        return list
    }

    fun addAccount(context: Context, account: UserAccount) {
        val accounts = getAccounts(context).toMutableList()
        if (accounts.none { it.username == account.username && it.url == account.url }) {
            accounts.add(account)
            saveAccounts(context, accounts)
        }
    }

    fun removeAccount(context: Context, username: String) {
        val accounts = getAccounts(context).filter { it.username != username }
        saveAccounts(context, accounts)
    }

    private fun saveAccounts(context: Context, accounts: List<UserAccount>) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val array = JSONArray()
        for (acc in accounts) {
            val obj = JSONObject().apply {
                put("name", acc.name)
                put("url", acc.url)
                put("username", acc.username)
                put("password", acc.password)
            }
            array.put(obj)
        }
        prefs.edit().putString(KEY_ACCOUNTS, array.toString()).apply()
    }
}