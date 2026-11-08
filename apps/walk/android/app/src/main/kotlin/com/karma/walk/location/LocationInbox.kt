package com.karma.walk.location

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

/**
 * 서비스가 Flutter 없이 받은 점을 바로 쓰는 앱 전용 SQLite 파일(`location_inbox.db`).
 * Dart 는 `drain` 으로 id 오름차순으로 읽어 drift 로 옮긴 뒤 `ack` 로 지운다(수거).
 * 시각 `t` 는 epoch millis(UTC), `still` 은 정지 진입 때 남긴 점이면 1.
 */
internal class LocationInbox private constructor(context: Context) :
    SQLiteOpenHelper(context, DB_NAME, null, DB_VERSION) {
    companion object {
        private const val DB_NAME = "location_inbox.db"
        private const val DB_VERSION = 1
        private const val TABLE = "points"

        @Volatile
        private var instance: LocationInbox? = null

        /** 서비스 · 채널이 같은 프로세스에서 하나를 나눠 쓴다(SQLiteOpenHelper 는 스레드 안전). */
        fun get(context: Context): LocationInbox =
            instance ?: synchronized(this) {
                instance ?: LocationInbox(context.applicationContext).also { instance = it }
            }
    }

    data class Point(
        val id: Long,
        val t: Long,
        val lat: Double,
        val lng: Double,
        val acc: Double?,
        val mode: String,
        val still: Boolean,
    )

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            "CREATE TABLE $TABLE (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "t INTEGER NOT NULL, " +
                "lat REAL NOT NULL, " +
                "lng REAL NOT NULL, " +
                "acc REAL, " +
                "mode TEXT NOT NULL, " +
                "still INTEGER NOT NULL DEFAULT 0)",
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit

    fun insert(t: Long, lat: Double, lng: Double, acc: Double?, mode: String, still: Boolean) {
        val values = ContentValues().apply {
            put("t", t)
            put("lat", lat)
            put("lng", lng)
            if (acc == null) putNull("acc") else put("acc", acc)
            put("mode", mode)
            put("still", if (still) 1 else 0)
        }
        writableDatabase.insert(TABLE, null, values)
    }

    /** 가장 오래된 점부터 [limit] 개(id 오름차순). 지우지 않는다. */
    fun drain(limit: Int): List<Point> {
        val points = mutableListOf<Point>()
        readableDatabase.query(
            TABLE,
            arrayOf("id", "t", "lat", "lng", "acc", "mode", "still"),
            null,
            null,
            null,
            null,
            "id ASC",
            limit.coerceAtLeast(0).toString(),
        ).use { cursor ->
            while (cursor.moveToNext()) {
                points += Point(
                    id = cursor.getLong(0),
                    t = cursor.getLong(1),
                    lat = cursor.getDouble(2),
                    lng = cursor.getDouble(3),
                    acc = if (cursor.isNull(4)) null else cursor.getDouble(4),
                    mode = cursor.getString(5),
                    still = cursor.getInt(6) != 0,
                )
            }
        }
        return points
    }

    /** [upToId] 이하를 지운다. 수거가 drift 에 다 옮긴 뒤 부른다. */
    fun ack(upToId: Long) {
        writableDatabase.delete(TABLE, "id <= ?", arrayOf(upToId.toString()))
    }

    /** 모두 지운다(아직 수거하지 않은 점까지). 기록 모두 지우기가 drift 보다 먼저 부른다. */
    fun clear() {
        writableDatabase.delete(TABLE, null, null)
    }
}
