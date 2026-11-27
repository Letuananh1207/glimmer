// Photo source (app plan app/docs/tasks/2026-11-27-kho-anh-tren-app.md): the device points at the app's library.
#include <unity.h>
#include "photo_source_core.h"

using namespace PhotoSource;

void setUp() {}
void tearDown() {}

void test_source_validation() {
    Source s;
    TEST_ASSERT_FALSE(setSource(s, "192.168.1", 8787, "abcdefgh12"));      // 3 parts
    TEST_ASSERT_FALSE(setSource(s, "192.168.1.256", 8787, "abcdefgh12"));
    TEST_ASSERT_FALSE(setSource(s, "phone.local", 8787, "abcdefgh12"));
    TEST_ASSERT_FALSE(setSource(s, "192.168.1.20", 0, "abcdefgh12"));
    TEST_ASSERT_FALSE(setSource(s, "192.168.1.20", 70000, "abcdefgh12"));
    TEST_ASSERT_FALSE(setSource(s, "192.168.1.20", 8787, "short"));
    TEST_ASSERT_FALSE(setSource(s, "192.168.1.20", 8787, "has/slash12"));     // goes into the URL path
    TEST_ASSERT_FALSE(s.set);
    TEST_ASSERT_EQUAL(NONE, stateOf(s));
    TEST_ASSERT_TRUE(setSource(s, "192.168.1.20", 8787, "Ab3dEfGh9k"));
    TEST_ASSERT_EQUAL_STRING("192.168.1.20", s.host);
    TEST_ASSERT_EQUAL(8787, s.port);
    TEST_ASSERT_EQUAL(ONLINE, stateOf(s));
}

void test_pointer_walks_the_library() {
    Source s;
    setSource(s, "192.168.1.20", 8787, "Ab3dEfGh9k");
    char p[64];
    TEST_ASSERT_TRUE(nextPath(s, p, sizeof(p)) > 0);
    TEST_ASSERT_EQUAL_STRING("/p/Ab3dEfGh9k/next?after=0", p);         // nothing on screen: the first
    fetched(s, 41, 1, 40);
    nextPath(s, p, sizeof(p));
    TEST_ASSERT_EQUAL_STRING("/p/Ab3dEfGh9k/next?after=41", p);
    TEST_ASSERT_EQUAL(1, s.index);
    TEST_ASSERT_EQUAL(40, s.count);
    // A cache photo on screen: the next remote one starts the library over.
    showingCache(s);
    nextPath(s, p, sizeof(p));
    TEST_ASSERT_EQUAL_STRING("/p/Ab3dEfGh9k/next?after=0", p);
    TEST_ASSERT_EQUAL(-1, nextPath(s, p, 10));                          // too small a buffer
}

void test_app_away_then_back() {
    Source s;
    TEST_ASSERT_FALSE(wantRemote(s, 0));                                // no source: cache only
    setSource(s, "192.168.1.20", 8787, "Ab3dEfGh9k");
    TEST_ASSERT_TRUE(wantRemote(s, 1000));
    fetched(s, 7, 2, 9);
    fetchFailed(s, 5000);
    TEST_ASSERT_EQUAL(OFFLINE, stateOf(s));
    TEST_ASSERT_EQUAL_STRING("offline", stateName(stateOf(s)));
    TEST_ASSERT_FALSE(s.remote);
    TEST_ASSERT_FALSE(wantRemote(s, 5000 + kRetryMs - 1));               // cache meanwhile
    TEST_ASSERT_TRUE(wantRemote(s, 5000 + kRetryMs));
    // The app opens again and says where it is: ask at once, same key keeps the place.
    fetchFailed(s, 90000);
    TEST_ASSERT_TRUE(setSource(s, "192.168.1.20", 8787, "Ab3dEfGh9k"));
    TEST_ASSERT_TRUE(wantRemote(s, 90001));
    TEST_ASSERT_EQUAL_UINT32(7, s.curId);
    // A restarted app (new key) starts from the first photo.
    TEST_ASSERT_TRUE(setSource(s, "192.168.1.21", 8787, "Zz9yXw8vUt"));
    TEST_ASSERT_EQUAL_UINT32(0, s.curId);
    clearSource(s);
    TEST_ASSERT_EQUAL(NONE, stateOf(s));
}

void test_empty_library_and_headers() {
    Source s;
    setSource(s, "10.0.0.2", 8787, "Ab3dEfGh9k");
    fetched(s, 3, 1, 1);
    emptyLibrary(s);
    TEST_ASSERT_EQUAL(ONLINE, stateOf(s));
    TEST_ASSERT_FALSE(s.remote);
    TEST_ASSERT_EQUAL(0, s.count);
    TEST_ASSERT_EQUAL_UINT32(12, headerNumber("12"));
    TEST_ASSERT_EQUAL_UINT32(0, headerNumber(""));
    TEST_ASSERT_EQUAL_UINT32(0, headerNumber(nullptr));
    TEST_ASSERT_EQUAL_UINT32(9, headerNumber("1x", 9));
}

int main(int, char**) {
    UNITY_BEGIN();
    RUN_TEST(test_source_validation);
    RUN_TEST(test_pointer_walks_the_library);
    RUN_TEST(test_app_away_then_back);
    RUN_TEST(test_empty_library_and_headers);
    return UNITY_END();
}
