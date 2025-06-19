from compat.py.deptree import get_dependency_tree as get_dependency_tree_py
from compat.py.show import get_versions as get_versions_py

tree = get_dependency_tree_py("pandas==1.1.1")
print(tree)

versions = get_versions_py("pandas")
print(versions)

from compat.go.deptree import get_dependency_tree as get_dependency_tree_go
from compat.go.show import get_versions as get_versions_go

tree = get_dependency_tree_go("github.com/gin-gonic/gin@v1.8.0")
print(tree)

versions = get_versions_go("github.com/gin-gonic/gin")
print(versions)

from compat.rust.deptree import get_dependency_tree as get_dependency_tree_rust
from compat.rust.show import get_versions as get_versions_rust

tree = get_dependency_tree_rust("serde==1.0.140")
print(tree)

versions = get_versions_rust("serde", limit=10)
print(versions)

from compat.java.deptree import get_dependency_tree as get_dependency_tree_java
from compat.java.show import get_versions as get_versions_java

tree = get_dependency_tree_java("org.springframework:spring-core:5.3.21")
print(tree)

versions = get_versions_java("org.springframework:spring-core", limit=10)
print(versions)

from compat.cpp.deptree import get_dependency_tree as get_dependency_tree_cpp
from compat.cpp.show import get_versions as get_versions_cpp

tree = get_dependency_tree_cpp("fmt", "vcpkg")
print(tree)

versions = get_versions_cpp("fmt", "vcpkg")
print(versions)