struct v2f
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 world_normal : TEXCOORD1;
    float4 world_pos : TEXCOORD2;
    float3 tangent: TEXCOORD3;
    float3 binormal: TEXCOORD4;
    float3 pixel_ambient: TEXCOORD5;
    UNITY_FOG_COORDS(6)
    SHADOW_COORDS(7)
    LIGHTING_COORDS(8 , 9)
};
struct appdata_k {
    float4 vertex : POSITION;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
    float4 texcoord : TEXCOORD0;
    float3 oldPos : TEXCOORD4;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

float _Glow;
float _SpecularSmooth;
float _SpecularStrength;
float _Metallic;
float _Rim;
float _RimSharpness;
float _Saturate;
float _ShadowBrightness;
float _ShadowSharpness;
float4 _ShadowColor;
float _ShadowOffset;
float _BumpScale;
float _LightMapSharpness;
float _SSS_Depth;
float _SSS_Strength;
float4 _SSS_Color;
float4 _HeadForward;
float _TextureDensity;
float _StockingStrength;
float _StockingPow;
float _StockingBase;
float _SH9;
float _Luminance;
#ifdef FURSTEP
    float _Shrink;
#endif

const float Epsilon = 1e-6;

sampler2D _MainTex;
sampler2D _NormalMap;
sampler2D _LightMap;
sampler2D _LightMapMask;
sampler2D _GlowTex;
sampler2D _SpecularMaskTex;
sampler2D _CurvatureMap;
sampler2D _BodyTex;
sampler2D _BodyMask;
float4 _MainTex_ST;
float4 _NormalMap_ST;
float4 _LightMap_ST;
float4 _LightMapMask_ST;
float4 _GlowTex_ST;
float4 _SpecularMaskTex_ST;
float4 _CurvatureMap_ST;
float4 _BodyTex_ST;
float4 _BodyMask_ST;
#ifdef DBSide
sampler2D _BackTex;
float4 _BackTex_ST;
#endif
#include "common.cginc"

v2f vert_base (appdata_k v)
{
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    float3 wnormal = UnityObjectToWorldNormal(v.normal);
    float3 defaultLightDirection = GetDefaultLightDirection();
    float anyLXYZ = any(_WorldSpaceLightPos0.xyz);
    float3 lightDirection = normalize(lerp(defaultLightDirection,_WorldSpaceLightPos0.xyz,anyLXYZ));
    wnormal = normalize(lerp(wnormal, lightDirection, anyLXYZ * 0.25));
    o.world_normal = wnormal;
    o.world_pos = mul(unity_ObjectToWorld, v.vertex);
    o.tangent = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
    o.binormal = normalize(cross(o.world_normal, o.tangent) * v.tangent.w);
    TRANSFER_SHADOW(o);
    UNITY_TRANSFER_FOG(o,o.pos);
    o.pixel_ambient = GetPixelAmbient(o.world_pos);
	TRANSFER_VERTEX_TO_FRAGMENT(o);
    return o;
}

float4 frag_base (v2f i, fixed facing : VFACE) : SV_Target
{
    #ifdef DBSide
    [branch]
    float4 base = 0;
    if(facing > 0)
        base = tex2D(_MainTex, TRANSFORM_TEX(i.uv, _MainTex));
    else
        base = tex2D(_BackTex, TRANSFORM_TEX(i.uv, _BackTex));
    #else
    float4 base = tex2D(_MainTex, TRANSFORM_TEX(i.uv, _MainTex));
    #endif
    if(base.a < 0.05)
    discard;

	float3 light_color = _LightColor0 * LIGHT_ATTENUATION(i) * 0.6f;

    return float4(saturate(light_color * base.rgb * _Luminance), base.a);
}
