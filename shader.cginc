struct v2f
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 world_normal : TEXCOORD1;
    float4 world_pos : TEXCOORD2;
    float3 tangent: TEXCOORD3;
    float3 binormal: TEXCOORD4;
    UNITY_FOG_COORDS(5)
    SHADOW_COORDS(6)
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

#ifdef TESSELLATION_ON
v2f vert_base (VertexInput v)
#else
v2f vert_base (appdata_k v)
#endif
{
    v2f o;
    #ifdef FUR_BIAS
        v.vertex = v.vertex - float4(FUR_BIAS * v.normal * _Shrink,0);
    #endif
    o.pos = UnityObjectToClipPos(v.vertex);
    #ifdef TESSELLATION_ON
    o.uv = v.texcoord0;
    #else
    o.uv = v.texcoord;
    #endif
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

    float3x3 tangentTransform = float3x3( normalize(i.tangent), normalize(i.binormal), normalize(i.world_normal * facing));
    float3 normalMap = UnpackScaleNormal(tex2D(_NormalMap,TRANSFORM_TEX(i.uv, _NormalMap)), _BumpScale);
    float3 N = normalize(mul( normalMap, tangentTransform ));
    float3 V = normalize(_WorldSpaceCameraPos - i.world_pos.xyz);
    float3 L, lightColor, ambient, pixelAmbient;
    GetLightAmbient(i.world_pos.xyz, N, L, lightColor, ambient, pixelAmbient);

    #ifdef NO_CASTED_SHADOW
        float light_atten = 1;
    #elif defined (FURSTEP)
        float light_atten = 0;
    #else
        UNITY_LIGHT_ATTENUATION(light_atten, i, i.world_pos.xyz);
    #endif
    
    light_atten = lerp(1, light_atten, any(_WorldSpaceLightPos0.xyz));
    float3 shadedColor = shading_frag(base.rgb, lightColor, light_atten, ambient, pixelAmbient, N, V, L, i.uv, i.world_pos);
    float3 glow = tex2D(_GlowTex, TRANSFORM_TEX(i.uv, _GlowTex));
    shadedColor = lerp(shadedColor, base.rgb, glow * _Glow);
    UNITY_APPLY_FOG(i.fogCoord, shadedColor);
    return float4(saturate(shadedColor * _Luminance), base.a);
}

#ifdef FURSTEP
    float _FurLength;
    float _FurDensity;
    float _FurThinness;
    float4 _ForceGlobal;
    float4 _ForceLocal;

    sampler2D _FurTex;

    v2f vert_fur(appdata_k v)
    {
        UNITY_SETUP_INSTANCE_ID(v);
        v2f o;
        v.vertex = v.vertex - float4(FUR_BIAS * v.normal * _Shrink, 0);
        float fact = saturate(FURSTEP + 0.2);
        float4 global_force = _ForceGlobal;
        float3 global_dir = mul(unity_WorldToObject, global_force).xyz * pow(fact, 4);
        float4 local_force = _ForceLocal;
        float3 local_dir = local_force.xyz * pow(fact, 2);
        float3 comb_dir = normalize(v.normal + global_dir + local_dir);

        float3 P = v.vertex.xyz + comb_dir * _FurLength * FURSTEP * 0.1;

        o.pos = UnityObjectToClipPos(float4(P, 1.0));
        o.uv = v.texcoord;
        float3 wnormal = UnityObjectToWorldNormal(v.normal);
        float3 defaultLightDirection = normalize(UNITY_MATRIX_V[2].xyz + UNITY_MATRIX_V[1].xyz);
        float anyLXYZ = any(_WorldSpaceLightPos0.xyz);
        float3 lightDirection = normalize(lerp(defaultLightDirection,_WorldSpaceLightPos0.xyz,anyLXYZ));
        wnormal = normalize(lerp(wnormal, lightDirection, anyLXYZ * 0.25));
        o.world_normal = wnormal;
        o.world_pos = mul(unity_ObjectToWorld, P);
        UNITY_TRANSFER_FOG(o,o.pos);
        return o;
    }

    float4 frag_fur(v2f i): SV_Target
    {
        float noise = tex2D(_FurTex, i.uv * _FurThinness).r;
        noise = max(noise, 0.05);
        noise = pow(noise, 0.1 + _FurDensity);
        float alpha = clamp(noise * 1.2 - 
        (pow(FURSTEP,0.52)+FURSTEP*0.1),
        0, 1);

        float3 N = normalize(i.world_normal);
        float3 V = normalize(_WorldSpaceCameraPos - i.world_pos.xyz);
        float3 L, lightColor, ambient, pixelAmbient;
        GetLightAmbient(i.world_pos.xyz, N, L, lightColor, ambient, pixelAmbient);
        float4 base = tex2D(_MainTex, TRANSFORM_TEX(i.uv, _MainTex));
        base.rgb = base.rgb * lerp(0.6, 1, pow(FURSTEP*2.4,0.2));
        float light_atten = 1;

        float3 shadedColor = shading_frag(base.rgb, lightColor, light_atten, ambient, pixelAmbient, N, V, L);
        UNITY_APPLY_FOG(i.fogCoord, shadedColor);
        return float4(saturate(shadedColor * _Luminance), alpha);
    }
#endif

#ifdef TESSELLATION_ON
#ifdef UNITY_CAN_COMPILE_TESSELLATION
            // tessellation domain shader
            [UNITY_domain("tri")]
            v2f ds_surf(UnityTessellationFactors tessFactors, const OutputPatch<InternalTessInterp_VertexInput, 3> vi, float3 bary : SV_DomainLocation)
            {
                VertexInput v = _ds_VertexInput(tessFactors, vi, bary);
                return vertexshader(v);
            }
#endif // UNITY_CAN_COMPILE_TESSELLATION
#endif // TESSELLATION_ON
