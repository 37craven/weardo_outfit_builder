from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from rembg import remove
from PIL import Image
import io

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/remove-bg")
async def remove_bg(image: UploadFile = File(...)):
    input_bytes = await image.read()
    input_image = Image.open(io.BytesIO(input_bytes))
    output_image = remove(input_image)
    output_bytes = io.BytesIO()
    output_image.save(output_bytes, format="PNG")
    output_bytes.seek(0)
    return Response(content=output_bytes.read(), media_type="image/png")


@app.get("/health")
async def health():
    return {"status": "ok"}
