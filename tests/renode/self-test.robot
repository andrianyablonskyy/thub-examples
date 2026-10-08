*** Settings ***
Suite Setup       Setup
Suite Teardown    Teardown
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Test Cases ***
Boots and passes the self-test
    Execute Command           mach create
    Execute Command           machine LoadPlatformDescription @platforms/boards/stm32f4_discovery-kit.repl
    Execute Command           sysbus LoadELF @${ELF}
    Create Terminal Tester    sysbus.usart2
    Start Emulation
    Wait For Line On Uart     self-test: PASSED    timeout=30
