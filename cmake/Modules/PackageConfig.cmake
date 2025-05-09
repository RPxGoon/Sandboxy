set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "A free open-source voxel game engine with easy modding and game creation.")
set(CPACK_PACKAGE_VENDOR "Sandboxy")
set(CPACK_PACKAGE_CONTACT "https://github.com/sandboxyorg/sandboxy/issues")
set(CPACK_COMPONENT_DOCS_DISPLAY_NAME "Documentation")
set(CPACK_COMPONENT_DOCS_DESCRIPTION "Documentation about Sandboxy and its modding capabilities")

# Package version from GetGitDescribe.cmake
include(GetGitDescribe)
set_pkg_metadata()
set(CPACK_PACKAGE_VERSION_MAJOR ${VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${VERSION_PATCH})

# Windows-specific settings
if(WIN32)
    if(RUN_IN_PLACE)
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
            set(CPACK_PACKAGE_FILE_NAME "${PROJECT_NAME}-${VERSION_STRING}-win64")
        else()
            set(CPACK_PACKAGE_FILE_NAME "${PROJECT_NAME}-${VERSION_STRING}-win32") 
        endif()

        set(CPACK_GENERATOR ZIP)
    else()
        set(CPACK_GENERATOR WIX)
        set(CPACK_PACKAGE_NAME "${PROJECT_NAME_CAPITALIZED}")
        set(CPACK_PACKAGE_INSTALL_DIRECTORY ".")
        set(CPACK_PACKAGE_EXECUTABLES ${PROJECT_NAME} "${PROJECT_NAME_CAPITALIZED}")
        set(CPACK_CREATE_DESKTOP_LINKS ${PROJECT_NAME})

        set(CPACK_WIX_PRODUCT_ICON "${CMAKE_CURRENT_SOURCE_DIR}/misc/sandboxy-icon.ico")
        set(CPACK_WIX_UI_BANNER "${CMAKE_CURRENT_SOURCE_DIR}/misc/CPACK_WIX_UI_BANNER.BMP")
        set(CPACK_WIX_UI_DIALOG "${CMAKE_CURRENT_SOURCE_DIR}/misc/CPACK_WIX_UI_DIALOG.BMP")
        set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/doc/lgpl-2.1.txt")
        
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
            set(CPACK_WIX_UPGRADE_GUID "745A0FB3-5552-44CA-A587-A91C397CCC56")
        else()
            set(CPACK_WIX_UPGRADE_GUID "814A2E2D-2779-4BBD-9ACD-FC3BD51FBBA2")
        endif()
    endif()

# macOS-specific settings  
elseif(APPLE)
    set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY 0)
    set(CPACK_PACKAGE_FILE_NAME "${PROJECT_NAME}-${VERSION_STRING}-osx")
    set(CPACK_GENERATOR ZIP)

# Linux-specific settings
else()
    set(CPACK_PACKAGE_FILE_NAME "${PROJECT_NAME}-${VERSION_STRING}-linux")
    set(CPACK_GENERATOR TGZ)
    set(CPACK_SOURCE_GENERATOR TGZ)
endif()