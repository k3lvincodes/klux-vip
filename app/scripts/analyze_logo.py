from PIL import Image
from collections import Counter

img = Image.open('assets/images/kenick_logo.png').convert('RGB')
data = img.getdata()
counts = Counter(data)
for color, count in counts.most_common(5):
    print(f"Color: {color}, Count: {count}")
