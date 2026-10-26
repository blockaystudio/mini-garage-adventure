from pathlib import Path
from PIL import Image
import hashlib, json
base = Path(__file__).parent
regions = {'drive':(950,265,1035,300), 'brake':(1120,265,1205,300), 'reverse':(950,360,1035,395), 'left':(1120,360,1205,395), 'right':(950,455,1035,490), 'stop':(1120,455,1205,490), 'close':(950,575,1205,615)}
results = []
for path in [base.parent/'accessible-3d-linux.png', *sorted(base.glob('garage-accessible-3d-*.png'))]:
    image = Image.open(path).convert('RGB')
    counts = {name:sum(r>200 and g>190 and b>150 for r,g,b in image.crop(rect).get_flattened_data()) for name, rect in regions.items()}
    results.append({'path':str(path.relative_to(base.parent)), 'sha256':hashlib.sha256(path.read_bytes()).hexdigest(), 'cream_pixel_counts':counts})
print(json.dumps({'scope':'Checks decoded light-colored pixels in known button-label rectangles; not OCR, a mobile result, or proof of accessibility.', 'frames':results},indent=2))
