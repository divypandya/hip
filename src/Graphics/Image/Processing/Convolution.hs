{-# LANGUAGE BangPatterns #-}
module Graphics.Image.Processing.Convolution (
  Border(..), convolve, convolve', convolveRows, convolveCols,
  module Graphics.Image.Processing.Complex.Fourier
  ) where

import Graphics.Image.Interface
import Graphics.Image.Processing.Geometric
import Graphics.Image.Processing.Complex.Fourier



convolve'' :: Array arr cs e =>
              Border (Pixel cs e) -> Image arr cs e -> Image arr cs e -> Image arr cs e
convolve'' !border !kernel !img = traverse2 kernel img (const . const sz) stencil where
  !(krnM, krnN)     = dims kernel
  !krnM2            = krnM `div` 2
  !krnN2            = krnN `div` 2
  !sz               = dims img
  getPxB !getPx !ix = borderIndex border sz getPx ix
  {-# INLINE getPxB #-}
  stencil !getKrnPx !getImgPx !(i, j) = integrate 0 0 0 where
    !ikrnM = i - krnM2
    !jkrnN = j - krnN2
    integrate !ki !kj !acc
      | kj == krnN            = integrate (ki+1) 0 acc
      | kj == 0 && ki == krnM = acc
      | otherwise             = let !krnPx = getKrnPx (ki, kj)
                                    !imgPx = getPxB getImgPx (ki + ikrnM, kj + jkrnN)
                                in integrate ki (kj + 1) (acc + krnPx * imgPx)
    {-# INLINE integrate #-}
  {-# INLINE stencil #-}
{-# INLINE convolve'' #-}


convolve  :: (Transformable arr' arr, Array arr' cs e, ManifestArray arr cs e) =>
             Border (Pixel cs e)   -- ^ Approach to be used near the borders.
          -> Image arr' cs e -- ^ Convolution kernel image.
          -> Image arr cs e -- ^ Image that will be convolved with the kernel.
          -> Image arr cs e
convolve !out = convolve'' out . transform (undefined :: arr) . rotate180
{-# INLINE convolve #-}


convolve'  :: Array arr cs e =>
              Border (Pixel cs e)   -- ^ Approach to be used near the borders.
           -> Image arr cs e -- ^ Convolution kernel image.
           -> Image arr cs e -- ^ Image that will be convolved with the kernel.
           -> Image arr cs e
convolve' !out = convolve'' out . rotate180
{-# INLINE convolve' #-}


convolveRows :: ManifestArray arr cs e =>
                Border (Pixel cs e) -> [Pixel cs e] -> Image arr cs e -> Image arr cs e
convolveRows !out = convolve' out . fromLists . (:[]) . reverse
{-# INLINE convolveRows #-}


convolveCols :: ManifestArray arr cs e =>
                Border (Pixel cs e) -> [Pixel cs e] -> Image arr cs e -> Image arr cs e
convolveCols !out = convolve' out . transpose . fromLists . (:[]) . reverse
{-# INLINE convolveCols #-}

