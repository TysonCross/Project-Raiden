import cv2
from pycine.color import color_pipeline, resize
from pycine.raw import read_frames


cine_file = '/mnt/Shield/ELEN4012 Videos/HS_Lightning_videos/20170210_163916_ng.cine'
start_frame = 1
count = 1

raw_images, setup, bpp = read_frames(cine_file, start_frame=start_frame, count=count)
rgb_images = (color_pipeline(raw_image, setup=setup, bpp=bpp) for raw_image in raw_images)

for i, rgb_image in enumerate(rgb_images):
    frame = start_frame + i

    # if setup.EnableCrop:
    #     rgb_image = rgb_image[
    #         setup.CropRect.top : setup.CropRect.bottom + 1, setup.CropRect.left : setup.CropRect.right + 1
    #     ]
    #
    # if setup.EnableResample:
    #     rgb_image = cv2.resize(rgb_image, (setup.ResampleWidth, setup.ResampleHeight))

cv2.imshow('image', cine_file)
cv2.waitKey(0)
cv2.destroyAllWindows()
