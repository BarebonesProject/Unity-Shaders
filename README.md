# Description

Barebone HLSL shaders, for Unity 3D, URP (HDRP?).

# Shaders

## Blit.shader

```csharp
Graphics.Blit(srcTexture, targetTexture, material, 0);
```

## Forward - single.shader

For the `forward` path.

## Fullscreen.shader

For the fullscreen render feature.

## GBuffer - simple.shader

A simple [GBuffer](https://docs.unity3d.com/6000.0/Documentation/Manual/urp/rendering/g-buffer-layout.html) shader (`deferred` path).

## GBuffer - BRDF.shader

A BRDF (PBR) [GBuffer](https://docs.unity3d.com/6000.0/Documentation/Manual/urp/rendering/g-buffer-layout.html) shader (`deferred` path).
