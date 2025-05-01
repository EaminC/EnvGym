from dataclasses import dataclass, field
from typing import Self


@dataclass
class VectorStoreItem:
    embedding: list[float]
    document: str


@dataclass
class VectorStore:
    items: list[VectorStoreItem] = field(default_factory=list)

    def add(self, item: VectorStoreItem) -> Self:
        self.items.append(item)
        return self

    def search(
        self, query_embedding: list[float], top_k: int = 5
    ) -> list[VectorStoreItem]:
        result = sorted(
            self.items,
            key=lambda item: self._cosine_similarity(query_embedding, item.embedding),
            reverse=True,
        )[:top_k]
        return result

    def _cosine_similarity(self, v1: list[float], v2: list[float]) -> float:
        dot_product = sum(a * b for a, b in zip(v1, v2))
        magnitude_v1 = sum(a**2 for a in v1) ** 0.5
        magnitude_v2 = sum(b**2 for b in v2) ** 0.5
        return dot_product / (magnitude_v1 * magnitude_v2)
