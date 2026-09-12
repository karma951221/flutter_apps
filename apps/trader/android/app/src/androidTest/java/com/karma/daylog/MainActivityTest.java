package com.karma.daylog;

import androidx.test.platform.app.InstrumentationRegistry;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;

import pl.leancode.patrol.PatrolJUnitRunner;

/**
 * Patrol 이 Dart 테스트 목록을 읽어 JUnit 테스트 케이스로 펼쳐주는 진입점.
 *
 * 이 파일은 Patrol 이 요구하는 고정 보일러플레이트다. 테스트 내용은
 * app/patrol_test/*.dart 에만 쓰고 여기는 건드리지 않는다.
 */
@RunWith(Parameterized.class)
public class MainActivityTest {

    @Parameterized.Parameters(name = "{0}")
    public static Object[] testCases() {
        PatrolJUnitRunner instrumentation =
                (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.setUp(MainActivity.class);
        instrumentation.waitForPatrolAppService();
        return instrumentation.listDartTests();
    }

    private final String dartTestName;

    public MainActivityTest(String dartTestName) {
        this.dartTestName = dartTestName;
    }

    @Test
    public void runDartTest() {
        PatrolJUnitRunner instrumentation =
                (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.runDartTest(dartTestName);
    }
}
