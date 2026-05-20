import sys
from PIL import Image

def process_logo(input_path, output_light_path, output_dark_path, bg_tolerance=30, white_tolerance=80):
    img = Image.open(input_path).convert("RGBA")
    data = img.getdata()
    
    dark_mode_data = []
    light_mode_data = []
    
    # We know the background is basically black (0,0,0)
    bg_color = (0, 0, 0)
    # The logo text is white (255,255,255)
    white_color = (255, 255, 255)
    
    for item in data:
        # Check if it's black background
        is_bg = (item[0] < bg_tolerance and item[1] < bg_tolerance and item[2] < bg_tolerance)
        
        # Check if it's white text
        is_white = (item[0] > 255 - white_tolerance and 
                   item[1] > 255 - white_tolerance and 
                   item[2] > 255 - white_tolerance)
        
        if is_bg:
            # Make background transparent for both
            dark_mode_data.append((255, 255, 255, 0))
            light_mode_data.append((255, 255, 255, 0))
        elif is_white:
            # Dark mode keeps white text
            dark_mode_data.append(item)
            # Light mode turns white text to black
            # We keep the alpha channel
            light_mode_data.append((0, 0, 0, item[3]))
        else:
            # Keep gold colors as they are for both
            dark_mode_data.append(item)
            light_mode_data.append(item)
            
    # Save Dark Mode Logo
    img_dark = Image.new("RGBA", img.size)
    img_dark.putdata(dark_mode_data)
    img_dark.save(output_dark_path, "PNG")
    print(f"Saved transparent dark-mode logo to {output_dark_path}")
    
    # Save Light Mode Logo
    img_light = Image.new("RGBA", img.size)
    img_light.putdata(light_mode_data)
    img_light.save(output_light_path, "PNG")
    print(f"Saved transparent light-mode logo to {output_light_path}")

if __name__ == "__main__":
    input_file = "assets/images/kenick_logo.png"
    output_dark = "assets/images/kenick_logo_transparent_dark.png"
    output_light = "assets/images/kenick_logo_transparent_light.png"
    process_logo(input_file, output_light, output_dark)
