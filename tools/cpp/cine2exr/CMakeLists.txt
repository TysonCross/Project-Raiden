cmake_minimum_required(VERSION 3.14)
project(cine2exr LANGUAGES CXX )

set(CMAKE_CXX_STANDARD 14)
# set(CMAKE_BUILD_TYPE "Debug")
# set(CMAKE_VERBOSE_MAKEFILE ON)
# set (CMAKE_CXX_FLAGS "-O0")
# set (CMAKE_CXX_FLAGS "-O3")
# set (CMAKE_CXX_FLAGS "-Wno-unused-command-line-argument")

set(EXECUTABLE ${PROJECT_NAME})
set(CINEREADER_DIR /usr/local/CineReader)
set(CINEREADER_INCLUDE_DIR ${CINEREADER_DIR}/includes)
set(CINEREADER_LIB_DIR ${CINEREADER_DIR}/lib)

set(SOURCE
        src/main.cpp)

set(HEADER_FILES
        ${CINEREADER_INCLUDE_DIR}/data.h
        ${CINEREADER_INCLUDE_DIR}/bitreader.h
        ${CINEREADER_INCLUDE_DIR}/cinefileheader.h
        ${CINEREADER_INCLUDE_DIR}/bitmapinfoheader.h
        ${CINEREADER_INCLUDE_DIR}/imageoffsets.h
        ${CINEREADER_INCLUDE_DIR}/cinereader.h
        ${CINEREADER_INCLUDE_DIR}/cineimage.h
        ${CINEREADER_INCLUDE_DIR}/setup.h)

#find_package(OpenMP REQUIRED)
#if (OPENMP_FOUND)
#    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS} ")
#    set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}")
#endif()

ADD_LIBRARY(CineReader STATIC IMPORTED)
SET_TARGET_PROPERTIES(CineReader PROPERTIES IMPORTED_LOCATION ${CINEREADER_LIB_DIR}/libcinereader.a)

add_executable(${PROJECT_NAME} ${SOURCE})
target_include_directories(${EXECUTABLE} PRIVATE ${CINEREADER_INCLUDE_DIR})
target_link_libraries(${EXECUTABLE} CineReader)

