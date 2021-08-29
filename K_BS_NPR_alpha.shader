Shader "KBSToon/Transparent"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_GlowTex ("GlowTexture", 2D) = "white" {}
		_Glow ("Glow", Range (0, 1)) = 0
		_Rim ("Rim", Range (0, 1)) = 0
		_RimSharpness ("RimSharpness", Range (0, 1)) = 0
		_Saturate ("Saturate", Range (-1, 1)) = 0
		_ShadowBrightness ("ShadowBrightness", Range (-1, 1)) = 0
		_ShadowSharpness ("ShadowSharpness", Range (0, 1)) = 0
		_ShadowOffset ("ShadowOffset", Range (0, 1)) = 0.5
		_ShadowColor ("ShdowColor", Color) = (1,1,1,1)
		_NormalMap ("NormalMap", 2D) = "bump" {}
        _BumpScale ("Normal Scale", Range(0, 2)) = 1
		[Toggle(__IsShadingFace)] __IsShadingFace("ShadingFace", Float)=0
		_LightMap ("FaceLightMap", 2D) = "black" {}
		_LightMapMask ("FaceLightMapMask", 2D) = "white" {}
		_LightMapSharpness ("LightMapSharpness", Range (0, 1)) = 0
		[Toggle(__IsSSS)] __IsSSS("SSS", Float)=0
		_SSS_Depth ("SSS_Depth", Range (0, 1)) = 0
		_SSS_Strength ("SSS_Strength", Range (0, 1)) = 0.2
		_SSS_Color ("SSS_Color", Color) = (1,1,1,1)
		[HideInInspector] _HeadForward ("HeadForward", Vector) = (0,0,1,0)
		_SH9 ("SH9", Range (0, 1)) = 0
		_Luminance ("Luminance", Range (0, 2)) = 1
	}
	Category {
		Fog { Mode Off }
		Tags { "Queue"="Transparent" "RenderType"="Transparent"}
		LOD 100
		Cull Off
		Blend SrcAlpha OneMinusSrcAlpha
		SubShader
		{
			CGINCLUDE
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			ENDCG
			Tags { "LightMode" = "ForwardBase" }
			Pass
			{
				CGPROGRAM
				#pragma shader_feature __IsShadingFace
				#pragma shader_feature __IsSSS
				#pragma vertex vert_base
				#pragma fragment frag_base
				#include "shader.cginc"
				ENDCG
			}
		}
	}

	Fallback Off
}
