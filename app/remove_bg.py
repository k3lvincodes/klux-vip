import sys
from PIL import Image

def remove_background(input_path, output_path, tolerance=15):
    img = Image.open(input_path).convert("RGBA")
    data = img.getdata()
    
    # Get the background color from the top-left pixel
    bg_color = data[0]
    
    new_data = []
    for item in data:
        # Check if pixel is similar to background color within tolerance
        if (abs(item[0] - bg_color[0]) < tolerance and
            abs(item[1] - bg_color[1]) < tolerance and
            abs(item[2] - bg_color[2]) < tolerance):
            # Make transparent
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    img.save(output_path, "PNG")
    print(f"Saved transparent logo to {output_path}")

if __name__ == "__main__":
    input_file = "assets/images/kenick_logo.png"
    output_file = "assets/images/kenick_logo_transparent.png"
    remove_background(input_file, output_file, tolerance=30)
