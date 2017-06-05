namespace Uvc {
    extern void bayer_to_rgb24([CCode (array_length = false)]
                               uint8[] pBay,
                               [CCode (array_length = false)]
                               uint8[] pRGB24,
                               int width, int height, int pix_order);
}
