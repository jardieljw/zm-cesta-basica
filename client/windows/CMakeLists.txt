cmake_minimum_required(VERSION 3.14)
project(zm_cesta_basica_client LANGUAGES CXX)

set(BINARY_NAME "zm_cesta_basica_client")

cmake_policy(SET CMP0079 NEW)

add_subdirectory("flutter")

add_executable(${BINARY_NAME} WIN32
  "runner/main.cpp"
  "runner/utils.cpp"
  "runner/win32_window.cpp"
  "runner/flutter_window.cpp"
  "runner/Runner.rc"
)

apply_standard_settings(${BINARY_NAME})
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
