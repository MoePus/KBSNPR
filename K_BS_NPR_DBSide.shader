Shader "KBSToon/Default_Cutout_DBSide"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BackTex ("BackTexture", 2D) = "white" {}
		_GlowTex ("GlowTexture", 2D) = "white" {}
		_Glow ("Glow", Range (0, 1)) = 0
		_SpecularMaskTex ("SpecularMaskTex", 2D) = "black" {}
		_SpecularSmooth ("SpecularSmooth", Range (0, 1)) = 0
		_SpecularStrength ("SpecularStrength", Range (0, 2)) = 1
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
		_CurvatureMap ("CurvatureMap", 2D) = "black" {}
		_SSS_Depth ("SSS_Depth", Range (0, 1)) = 0
		_SSS_Strength ("SSS_Strength", Range (0, 1)) = 0.2
		_SSS_Color ("SSS_Color", Color) = (1,1,1,1)
		[Toggle(__IsStocking)] __IsStocking("Stocking", Float)=0
		_BodyTex ("BodyTex", 2D) = "white" {}
		_BodyMask ("BodyMask", 2D) = "white" {}
		//_TextureDensity ("TextureDensity", Range (0.01, 1)) = 1
		_StockingPow ("Pow", Range (1, 6)) = 3
		_StockingStrength ("Strength", Range (0, 1)) = 1
		_StockingBase ("Base", Range (-1, 1)) = 0
		[HideInInspector] _HeadForward ("HeadForward", Vector) = (0,0,1,0)
		_SH9 ("SH9", Range (0, 1)) = 0
		_Luminance ("Luminance", Range (0, 2)) = 1
	}

	SubShader
	{
		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" "Queue" = "Geometry" "RenderType" = "Opaque" }
			Cull Off
			CGPROGRAM
			#define DBSide 1
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma shader_feature __IsShadingFace
			#pragma shader_feature __IsSSS
			#pragma shader_feature __IsStocking
			#pragma vertex vert_base
			#pragma fragment frag_base
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" "Queue" = "Geometry" "RenderType" = "Opaque" }
			Offset 1, 1
			Cull Off
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			struct VertexInput {
				float4 vertex : POSITION;
			};
			struct VertexOutput {
				V2F_SHADOW_CASTER;
			};
			VertexOutput vert (VertexInput v) {
				VertexOutput o = (VertexOutput)0;
				o.pos = UnityObjectToClipPos( v.vertex );
				TRANSFER_SHADOW_CASTER(o)
				return o;
			}
			float4 frag(VertexOutput i) : SV_TARGET {
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
	

	FallBack "Diffuse"
}
