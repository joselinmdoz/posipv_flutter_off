from PIL import Image

img = Image.open('assets/icons/app_icon.png')
# Convert to RGBA
img = img.convert("RGBA")
datas = img.getdata()

# We want to find the bounding box of the non-white/transparent pixels
new_data = []
for item in datas:
    # change all white (also shades of white)
    # let's be strict: if R>240, G>240, B>240 we make it transparent
    if item[0] > 240 and item[1] > 240 and item[2] > 240:
        new_data.append((255, 255, 255, 0))
    else:
        new_data.append(item)

img.putdata(new_data)
# Now get bounding box of the non-transparent pixels
bbox = img.getbbox()
if bbox:
    cropped = img.crop(bbox)
    # Save the huge icon so that it occupies the whole thing, but we resize it to 512x512 with some padding
    # Wait, Android adaptive icon foreground expects 108x108 where the center 72x72 is the icon. So it needs some padding.
    # Let's just padding by 20%
    w, h = cropped.size
    from math import ceil
    pad_w = int(w * 0.2)
    pad_h = int(h * 0.2)
    new_w = w + pad_w * 2
    new_h = h + pad_h * 2
    background = Image.new('RGBA', (new_w, new_h), (255, 255, 255, 0))
    background.paste(cropped, (pad_w, pad_h))
    background = background.resize((512, 512), Image.Resampling.LANCZOS)
    background.save('assets/icons/app_icon_adaptive_fg.png')
    print("Cropped successfully.")
else:
    print("Could not crop.")

