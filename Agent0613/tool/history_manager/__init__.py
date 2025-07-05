"""
History manager tool module.
This module provides interfaces for saving execution status to history.txt.
"""

from .entry import auto_save_to_history

__all__ = ['auto_save_to_history'] 