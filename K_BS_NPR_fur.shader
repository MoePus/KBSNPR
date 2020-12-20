Shader "KBSNPR/Fur"
{
	Properties
	{
		_Tex ("Texture", 2D) = "white" {}
		_GlowTex ("GlowTexture", 2D) = "white" {}
		_Glow ("Glow", Range (0, 1)) = 0
		_Rim ("Rim", Range (0, 1)) = 0
		_RimSharpness ("RimSharpness", Range (0, 1)) = 0
		_Saturate ("Saturate", Range (-1, 1)) = 0
		_ShadowBrightness ("ShadowBrightness", Range (-1, 1)) = 0
		_ShadowSharpness ("ShadowSharpness", Range (0, 1)) = 0
		_ShadowColor ("ShdowColor", Color) = (1,1,1,1)
		[HideInInspector] _HeadForward ("HeadForward", Vector) = (0,0,1,0)
		[NoScaleOffset] _FurTex ("Fur Pattern", 2D) = "white" { }
		_FurLength ("Fur Length", Range(0.0, 1)) = 0.5
		_FurDensity ("Fur Density", Range(0, 2)) = 0.11
		_FurThinness ("Fur Thinness", Range(0.01, 10)) = 1

		_ForceGlobal ("Force Global", Vector) = (0, 0, 0, 0)
		_ForceLocal ("Force Local", Vector) = (0, 0, 0, 0)
	}
	Category {
		Fog { Mode Off }
		LOD 100
		Cull Off
		Blend Off
		SubShader
		{
			Tags { "LightMode" = "ForwardBase" }
			Pass
			{
				Tags { "RenderType"="Opaque"}
				CGPROGRAM
				#pragma vertex vert_base
				#pragma fragment frag_base
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.05
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.1
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.15
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.2
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.25
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.3
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.35
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.4
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.45
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.5
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.55
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.6
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.65
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.7
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.75
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.8
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.85
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.9
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 0.95
				#include "shader.cginc"
				ENDCG
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert_fur
				#pragma fragment frag_fur
				#define FURSTEP 1.0
				#include "shader.cginc"
				ENDCG
			}
		}
	}

	Fallback "VertexLit"
}
