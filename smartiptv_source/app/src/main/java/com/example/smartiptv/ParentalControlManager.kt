package com.example.smartiptv

import android.content.Context

object ParentalControlManager {
    private const val PREF_NAME = "parental_prefs"
    private const val KEY_PIN = "parental_pin"

    // تعيين كلمة السر (الافتراضية 0000)
    fun setPin(context: Context, pin: String) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_PIN, pin).apply()
    }

    fun getPin(context: Context): String {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_PIN, "0000") ?: "0000"
    }

    // التحقق هل القسم مشفر (مثلاً الأقسام التي تحتوي على كلمات معينة)
    fun isCategoryLocked(context: Context, categoryName: String): Boolean {
        val lockedKeywords = listOf("adult", "+18", "XXX", "للكبار")
        return lockedKeywords.any { categoryName.contains(it, ignoreCase = true) }
    }

    fun validatePin(context: Context, inputPin: String): Boolean {
        return getPin(context) == inputPin
    }
}