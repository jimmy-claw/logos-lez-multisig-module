cmake_minimum_required(VERSION 3.16)
project(LogosLezMultisigApp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

find_package(Qt6 REQUIRED COMPONENTS Core Widgets Quick QuickWidgets)

if(NOT DEFINED LOGOS_LIBLOGOS_ROOT)
    message(FATAL_ERROR "LOGOS_LIBLOGOS_ROOT must be defined")
endif()
if(NOT DEFINED LOGOS_CPP_SDK_ROOT)
    message(FATAL_ERROR "LOGOS_CPP_SDK_ROOT must be defined")
endif()

message(STATUS "Using logos-liblogos at: ${LOGOS_LIBLOGOS_ROOT}")
message(STATUS "Using logos-cpp-sdk at: ${LOGOS_CPP_SDK_ROOT}")

include_directories(
    ${LOGOS_LIBLOGOS_ROOT}/include
    ${LOGOS_CPP_SDK_ROOT}/include
    ${LOGOS_CPP_SDK_ROOT}/include/cpp
    ${LOGOS_CPP_SDK_ROOT}/include/core
)

link_directories(
    ${LOGOS_LIBLOGOS_ROOT}/lib
    ${LOGOS_CPP_SDK_ROOT}/lib
)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

add_executable(logos-lez-multisig-app
    main.cpp
    mainwindow.cpp
    mainwindow.h
)

target_link_libraries(logos-lez-multisig-app PRIVATE
    Qt6::Core
    Qt6::Widgets
    Qt6::Quick
    Qt6::QuickWidgets
    logos_core
    logos_sdk
)

if(APPLE)
    set_target_properties(logos-lez-multisig-app PROPERTIES
        INSTALL_RPATH "@executable_path/../lib"
        BUILD_WITH_INSTALL_RPATH TRUE
    )
elseif(UNIX)
    set_target_properties(logos-lez-multisig-app PROPERTIES
        INSTALL_RPATH "$ORIGIN/../lib"
        BUILD_WITH_INSTALL_RPATH TRUE
    )
endif()

install(TARGETS logos-lez-multisig-app RUNTIME DESTINATION bin)
