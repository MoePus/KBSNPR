Shader "KBSNPR/Default"
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
		[Toggle(__IsShadingFace)] __IsShadingFace("ShadingFace", Float)=0
		_LightMap ("FaceLightMap", 2D) = "black" {}
		_LightMapMask ("FaceLightMapMask", 2D) = "white" {}
		_LightMapSharpness ("LightMapSharpness", Range (0, 1)) = 0
		[Toggle(__IsSSS)] __IsSSS("SSS", Float)=0
		_SSS_Depth ("SSS_Depth", Range (0, 1)) = 0
		_SSS_Strength ("SSS_Strength", Range (0, 1)) = 0.2
		_SSS_Color ("SSS_Color", Color) = (1,1,1,1)
		[HideInInspector] _HeadForward ("HeadForward", Vector) = (0,0,1,0)
	}
	Category {
		Fog { Mode Off }
		LOD 100
		Cull Off
		SubShader
		{
			CGINCLUDE
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			ENDCG
			Tags { "LightMode" = "ForwardBase" }
			Pass
			{
				Tags { "RenderType"="Opaque"}
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

	Fallback "VertexLit"
}
