Shader "KBSNPR/Default"
{
	Properties
	{
		_Tex ("Texture", 2D) = "white" {}
		_GlowTex ("GlowTexture", 2D) = "white" {}
		_Glow ("Glow", Range (0, 1)) = 0
		_Rim ("Rim", Range (0, 1)) = 0
		_Saturate ("Saturate", Range (-1, 1)) = 0
		_ShadowBrightness ("ShadowBrightness", Range (-1, 1)) = 0
		_ShadowColor ("ShdowColor", Color) = (1,1,1,1)
		[Toggle] _bFace("IsShadingFace", Float)=0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque"}
		LOD 100
		Cull Off
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "AutoLight.cginc"
            #pragma multi_compile_fwdbase
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 world_normal : TEXCOORD1;
				float4 world_pos : TEXCOORD2;
				LIGHTING_COORDS(3,4)
			};

			float4 _ShadowColor;
			float _Glow;
			float _ShadowBrightness;
			float _bFace;
			float _Saturate;
			float _Rim;
			const float Epsilon = 1e-10;

			sampler2D _Tex;
			sampler2D _GlowTex;
			float4 _Tex_ST;
			float4 _GlowTex_ST;
			
			v2f vert (appdata_full v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				o.world_normal = normalize(UnityObjectToWorldNormal(v.normal));
				o.world_pos = mul(unity_ObjectToWorld, v.vertex);
				TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}
			#define RGB2LUM float3(0.2125, 0.7154, 0.0721)
			float3 RGBtoHCV(in float3 RGB)
			{
				// Based on work by Sam Hocevar and Emil Persson
				float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0/3.0) : float4(RGB.gb, 0.0, -1.0/3.0);
				float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
				float C = Q.x - min(Q.w, Q.y);
				float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
				return float3(H, C, Q.x);
			}

			float3 RGBtoHSV(in float3 RGB)
			{
				float3 HCV = RGBtoHCV(RGB);
				float S = HCV.y / (HCV.z + Epsilon);
				return float3(HCV.x, S, HCV.z);
			}

			float3 HUEtoRGB(in float H)
			{
				float R = abs(H * 6 - 3) - 1;
				float G = 2 - abs(H * 6 - 2);
				float B = 2 - abs(H * 6 - 4);
				return saturate(float3(R,G,B));
			}

			float3 HSVtoRGB(in float3 HSV)
			{
				float3 RGB = HUEtoRGB(HSV.x);
				return ((RGB - 1) * HSV.y + 1) * HSV.z;
			}

			float3 shadeLightProb(float3 N)
			{
				// float3 dfront = float3(0,0,1);
				// float3 dback = -dfront;
				// float3 dleft = float3(-1,0,0);
				// float3 dright = -dleft;

				// float3 _front = ShadeSH9(float4(dfront,1));
				// float3 _back = ShadeSH9(float4(dback,1));
				// float3 _left = ShadeSH9(float4(dleft,1));
				// float3 _right = ShadeSH9(float4(dright,1));

				// float3 frontback = lerp(_back, _front, (dot(N, dfront) + 1) * 0.5 );
				// float3 leftright = lerp(_right, _left, (dot(N, dleft) + 1) * 0.5 );

				return ShadeSH9(float4(N,1));
				//return lerp(frontback, leftright, (dot(abs(N), dfront) + 1) * 0.5 );
			}

			float3 transformHS(float3 from, float3 to, float factor)
			{
				float3 fromHSV = RGBtoHSV(from);
				float3 toHSV = saturate(RGBtoHSV(to));
				toHSV.y = toHSV.y*0.2 + 0.8;
				float3 mediumHSV = float3(toHSV.xy, fromHSV.z);
				float3 medium = HSVtoRGB(mediumHSV);
				return lerp(from, medium, factor * pow(toHSV.z, 0.5));
			}

			float4 frag (v2f i) : SV_Target
			{
				float3 N = i.world_normal;
				N.y = N.y * (1 - _bFace * 0.1);
				N = normalize(N);
				float3 V = normalize(_WorldSpaceCameraPos - i.world_pos.xyz);
				float3 L = _WorldSpaceLightPos0.xyz;
				L.y = L.y * (1 - _bFace * 0.1);
				L = normalize(L);
				float4 base = tex2D(_Tex, TRANSFORM_TEX(i.uv, _Tex));
				if(base.a < 0.8)
					discard;
				
				float light_atten = lerp(LIGHT_ATTENUATION(i), 1, _bFace);
				float3 ambient = shadeLightProb(N);

				float3 tilebaseL = transformHS(base.rgb, ambient, 0.25);
				float3 tilebaseS = transformHS(base.rgb, ambient, 0.8);

				float3 tilebaseSHSV = RGBtoHSV(tilebaseS);
				tilebaseSHSV.y = saturate(tilebaseSHSV.y * (1 + _Saturate));
				tilebaseS = HSVtoRGB(tilebaseSHSV);

				float NL = saturate(dot(N,L));
				float NV = saturate(dot(N,V));
				float rim = pow(1-NV,5) > lerp(1,0.0,pow(_Rim,0.1)) + Epsilon;
				float atten = min(light_atten, NL);
				atten = max(atten, rim);
				float shadowBrightness = 0.78 + 0.22 * _ShadowBrightness;
				float3 shadowedColor = tilebaseS * shadowBrightness * _ShadowColor;

				float shadowFactor = saturate((atten * 10 - 2) * lerp(1,10,_bFace));
				shadowedColor = lerp(shadowedColor, tilebaseL, shadowFactor);

				float glow = tex2D(_GlowTex, TRANSFORM_TEX(i.uv, _GlowTex)).r;
				return float4(shadowedColor, glow * _Glow);
			}
			ENDCG
		}
	}
	Fallback "VertexLit"
}
