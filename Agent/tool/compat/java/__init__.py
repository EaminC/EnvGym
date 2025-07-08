"""Java dependency analysis module."""

from .deptree import get_dependency_tree
from .show import get_versions

__all__ = ['get_dependency_tree', 'get_versions'] 