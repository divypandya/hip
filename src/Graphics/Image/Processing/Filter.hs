{-# LANGUAGE BangPatterns          #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE TypeSynonymInstances  #-}
-- |
-- Module      : Graphics.Image.Processing.Filter
-- Copyright   : (c) Alexey Kuleshevich 2017
-- License     : BSD3
-- Maintainer  : Alexey Kuleshevich <lehins@yandex.ru>
-- Stability   : experimental
-- Portability : non-portable
--
module Graphics.Image.Processing.Filter
  ( -- * Filter
    Filter
  , Direction(..)
  , applyFilter
    -- * Gaussian
  , gaussianLowPass
  , gaussianBlur
    -- * Sobel
  , sobelFilter
  , sobelOperator
  ) where


import           Graphics.Image.Interface              as I
import           Graphics.Image.Processing.Convolution

-- | Filter that can be applied to an image.
--
-- @since 1.5.3
data Filter arr cs e = Filter
  { applyFilter :: Image arr cs e -> Image arr cs e -- ^ Apply a filter to an image
  }


data Direction
  = Vertical
  | Horizontal


-- | Create a Gaussian Filter.
--
-- @since 1.5.3
gaussianLowPass :: (Array arr cs e, Floating e, Fractional e) =>
                   Int -- ^ Radius
                -> e -- ^ Sigma
                -> Border (Pixel cs e) -- ^ Border resolution technique.
                -> Filter arr cs e
gaussianLowPass !r !sigma border =
  Filter (correlate border (transpose gV) . correlate border gV)
  where
    !gV = compute $ (gauss / scalar weight)
    !gauss = makeImage (1, n) getPx
    !weight = I.fold (+) 0 gauss
    !n = 2 * r + 1
    !sigma2sq = 2 * sigma ^ (2 :: Int)
    getPx (_, j) =
      promote $ exp (fromIntegral (-((j - r) ^ (2 :: Int))) / sigma2sq)
    {-# INLINE getPx #-}
{-# INLINE gaussianLowPass #-}



-- | Create a Gaussian Blur filter. Radius will be derived from standard
-- deviation: @ceiling (2*sigma)@. `Edge` border resolution is utilized. If
-- custom radius and/or border resolution is desired, `gaussianLowPass` can be
-- used instead.
--
-- @since 1.5.3
gaussianBlur :: (Array arr cs e, Floating e, RealFrac e) =>
                e -- ^ Sigma
             -> Filter arr cs e
gaussianBlur !sigma = gaussianLowPass (ceiling (2*sigma)) sigma Edge
{-# INLINE gaussianBlur #-}


sobelFilter :: Array arr cs e =>
               Direction -> Border (Pixel cs e) -> Filter arr cs e
sobelFilter dir !border =
  Filter (convolveCols border cV . convolveRows border rV)
  where
    !(rV, cV) =
      case dir of
        Vertical -> ([1, 2, 1], [1, 0, -1])
        Horizontal -> ([1, 0, -1], [1, 2, 1])
{-# INLINE sobelFilter #-}


sobelOperator :: (Array arr cs e, Floating e) => Image arr cs e -> Image arr cs e
sobelOperator !img = sqrt (sobelX ^ (2 :: Int) + sobelY ^ (2 :: Int))
  where !sobelX = applyFilter (sobelFilter Horizontal Edge) img
        !sobelY = applyFilter (sobelFilter Vertical Edge) img
{-# INLINE sobelOperator #-}