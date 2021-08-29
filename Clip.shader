Shader "KBSToon/Clip_Cutout"
{
	Properties
	{
	}
	Category {
		Fog { Mode Off }
		LOD 100
		Cull Off
		SubShader
		{
			Tags { "LightMode" = "Dummy" "RenderType"="Opaque" }
			Pass
			{
				HLSLPROGRAM
				#pragma vertex v 
				#pragma fragment f
				void v(){};
				void f(){};
				ENDHLSL
			}
		}
	}
	FallBack Off
}
