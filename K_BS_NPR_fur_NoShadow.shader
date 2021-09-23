Shader "KBSToon/Fur_Cutout_NoShadow"
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
		_NearOcclusion ("NearOcclusion", Range (0, 1)) = 0.6
		[HideInInspector] _HeadForward ("HeadForward", Vector) = (0,0,1,0)
		[NoScaleOffset] _FurTex ("Fur Pattern", 2D) = "white" { }
		_FurLength ("Fur Length", Range(0.0, 1)) = 0.5
		_FurDensity ("Fur Density", Range(0, 2)) = 0.11
		_FurThinness ("Fur Thinness", Range(0.01, 100)) = 1
		_Shrink ("Shrink", Range(0, 0.2)) = 0.1
		_ForceGlobal ("Force Global", Vector) = (0, 0, 0, 0)
		_ForceLocal ("Force Local", Vector) = (0, 0, 0, 0)
		_SH9 ("SH9", Range (0, 1)) = 0
		_Luminance ("Luminance", Range (0, 2)) = 1
	}
	SubShader
	{
		LOD 0
		Tags {
			"IgnoreProjector" = "True"
			"RenderType"      = "Transparent"
			"Queue"           = "AlphaTest"
			"LightMode"       = "ForwardBase"
		}
		Cull Off
		Blend SrcAlpha OneMinusSrcAlpha, Zero One
		CGINCLUDE
		#define FUR_BIAS 0.1
		#define No_Fur_Shadow
		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" "Queue" = "Geometry" "RenderType" = "Opaque" }
			Offset 1, 1
			ZWrite On
			CGPROGRAM			
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#undef TESSELLATION_ON
			#include "UnityCG.cginc"
			struct VertexOutput {
				V2F_SHADOW_CASTER;
			};
			VertexOutput vert (appdata_full v) {
				VertexOutput o = (VertexOutput)0;
				v.vertex = v.vertex - float4(FUR_BIAS * v.normal * 0.1,0);
				TRANSFER_SHADOW_CASTER(o);
				return o;
			}
			float4 frag(VertexOutput i) : SV_TARGET {
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
		Pass
		{
			Tags { "Queue" = "Geometry" "RenderType"="Opaque"}
			Blend Off
			ZWrite On
			CGPROGRAM
			#pragma multi_compile_fwdbase
			#include "AutoLight.cginc"
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_base
			#pragma fragment frag_base
			#define FURSTEP 0.05
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.1
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.18
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.26
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.34
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.42
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.5
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.54
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.58
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.64
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.67
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.70
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.73
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.76
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.79
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.82
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.85
			#include "shader.cginc"
			ENDCG
		}
		Pass
		{
			CGPROGRAM			
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define FURSTEP 0.85
			#include "shader.cginc"
			ENDCG
		}
	}
	FallBack "Diffuse"
}
