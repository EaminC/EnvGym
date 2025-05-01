from dataclasses import dataclass, field
import os

import httpx
from rich import print as rprint

from augmented.vector_store import VectorStore, VectorStoreItem


@dataclass
class EembeddingRetriever:
    embedding_model: str
    vector_store: VectorStore = field(default_factory=VectorStore)

    async def _embed(self, text: str) -> list[float] | None:
        base_url = os.environ.get("EMBEDDING_BASE_URL") or os.environ.get(
            "OPENAI_BASE_URL"
        )
        api_key = os.environ.get("EMBEDDING_KEY") or os.environ.get("OPENAI_API_KEY")
        url = f"{base_url}/embeddings"
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }
        data = {
            "model": self.embedding_model,
            "input": text,
            "encoding_format": "float",
        }
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, headers=headers, json=data)
                response.raise_for_status()
                rprint(response)
                resp_data = response.json()
                result: list[float] = resp_data["data"][0]["embedding"]
                rprint(result)
                return result
            except httpx.HTTPStatusError as http_err:
                print(f"HTTP error occurred: {http_err}")
            except Exception as err:
                print(f"An error occurred: {err}")

    async def embed_query(self, query: str) -> list[float] | None:
        result = await self._embed(query)
        return result

    async def embed_documents(self, document: str) -> list[float] | None:
        result = await self._embed(document)
        self.vector_store.add(VectorStoreItem(embedding=result, document=document))
        return result

    async def retrieve(self, query: str, top_k: int = 5) -> list[VectorStoreItem]:
        query_embedding = await self.embed_query(query)
        return self.vector_store.search(query_embedding, top_k)
