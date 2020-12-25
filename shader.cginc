struct v2f
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 world_normal : TEXCOORD1;
    float4 world_pos : TEXCOORD2;
    LIGHTING_COORDS(3,4)
};

float _Glow;
float _Rim;
float _RimSharpness;
float _Saturate;
float _ShadowBrightness;
float _ShadowSharpness;
float4 _ShadowColor;
float _LightMapSharpness;
float _SSS_Depth;
float _SSS_Strength;
float4 _SSS_Color;
float4 _HeadForward;


const float Epsilon = 1e-6;

sampler2D _Tex;
sampler2D _LightMap;
sampler2D _LightMapMask;
sampler2D _GlowTex;
float4 _Tex_ST;
float4 _LightMap_ST;
float4 _LightMapMask_ST;
float4 _GlowTex_ST;

v2f vert_base (appdata_full v)
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
    return ShadeSH9(float4(N,1));
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

float2 uv2LightMapuv(float2 uv, float inv)
{
    float2 mappeduv = (uv - _LightMap_ST.zw)* _LightMap_ST.xy;
    mappeduv.x = lerp(mappeduv.x, -mappeduv.x, inv);
    return mappeduv;
}

float Guassian(float x)
{
    return pow(1.084438,-pow((x-0.5)*24,2)/2);
}

float softEdge(float bottom, float range, float value)
{
    return saturate( (value - bottom) / range );
}

float3 shading_frag(float3 base, float light_atten, float3 N, float3 V, float3 L, float2 uv = 0, float3 world_pos = 0)
{
    float3 ambient = shadeLightProb(N);

    float3 tilebaseL = transformHS(base.rgb, ambient, 0.25);
    float3 tilebaseS = transformHS(base.rgb, ambient, 0.8);

    float3 tilebaseSHSV = RGBtoHSV(tilebaseS);
    tilebaseSHSV.y = saturate(tilebaseSHSV.y * (1 + _Saturate));
    tilebaseS = HSVtoRGB(tilebaseSHSV);

    float NL = saturate(dot(N,L));
    #ifdef FURSTEP
    NL += FURSTEP * FURSTEP * 0.5;
    #endif
    float NV = saturate(dot(N,V));
    float rim = saturate((pow(1-NV,lerp(4,5,_RimSharpness)) - lerp(1,0.0,pow(_Rim,0.1))) * lerp(5,50,_RimSharpness));
    #ifdef FURSTEP
    float Occlusion = lerp( 0.1 , 1.004 , FURSTEP * FURSTEP);
    rim *= Occlusion;
    #endif

    #ifdef __IsShadingFace
        float lightMapMask = tex2D(_LightMapMask, TRANSFORM_TEX(uv, _LightMapMask)).x;
        
        float2 lightMap = tex2D(_LightMap, uv2LightMapuv(uv, 0)).xw;
        float2 lightMapInv = tex2D(_LightMap, uv2LightMapuv(uv, 1)).xw;
        float3 Front = _HeadForward;
        float3 Right = -cross(float3(0,1,0), Front);
        float FrontL = clamp(-1,1,dot(normalize(Front.xz), normalize(L.xz)));
        float RightL = clamp(-1,1,dot(normalize(Right.xz), normalize(L.xz)));\
        float lightMapSoftRange = max(0.01, 0.3 * (1 - _LightMapSharpness));
        RightL = pow(RightL,5);
        float face_light_attenuation = (FrontL > 0) * min(
            softEdge(RightL - lightMapSoftRange * 0.5, lightMapSoftRange, lightMap.x),// (lightMap.x > RightL),
            softEdge(-RightL - lightMapSoftRange * 0.5, lightMapSoftRange, lightMapInv.x) //(lightMapInv.x > -RightL)
        );
        float UpL = saturate(dot(normalize(Front.yz), normalize(L.yz)));
        UpL = pow(UpL, 0.9);
        face_light_attenuation = min(UpL, face_light_attenuation);
        float atten = lerp(min(light_atten, NL), face_light_attenuation, min(lightMapMask, lightMap.y));
    #else
        float atten = min(light_atten, NL);
    #endif

    atten = max(atten, rim);
    float shadowBrightness = 0.78 + 0.22 * _ShadowBrightness;
    float3 shadowedColor = tilebaseS * shadowBrightness * _ShadowColor;

    float shadowFactor = saturate((atten * 2 - 0.2) * lerp(1, 250, _ShadowSharpness * _ShadowSharpness));
    float3 shadedColor = lerp(shadowedColor, tilebaseL, shadowFactor);

    #ifdef __IsSSS
        float curvature = saturate(length(fwidth(N)) /
        length(fwidth(world_pos.xyz)) / 100);
        float SSS_factor = Guassian(shadowFactor) * smoothstep(0,1,curvature);
        SSS_factor = pow(SSS_factor, lerp(1, 0.25, _SSS_Depth));

        // float3 shadedColorHSV = RGBtoHSV(shadedColor);
        // shadedColorHSV.y = saturate(shadedColorHSV.y * 
        // (1 + SSS_factor * lerp(0, 10, _SSS_Strength)));
        // shadedColor = HSVtoRGB(shadedColorHSV);
        shadedColor = lerp(shadedColor, _SSS_Color, SSS_factor * lerp(0, 4, _SSS_Strength) );
    #endif
    return shadedColor;
}

float4 frag_base (v2f i) : SV_Target
{
    float3 N = normalize(i.world_normal);
    float3 V = normalize(_WorldSpaceCameraPos - i.world_pos.xyz);
    float3 L = normalize(_WorldSpaceLightPos0.xyz);
    float4 base = tex2D(_Tex, TRANSFORM_TEX(i.uv, _Tex));
    if(base.a < 0.8)
        discard;
    
    #ifdef __IsShadingFace
        float light_atten = 1;
    #else
        float light_atten = LIGHT_ATTENUATION(i);
    #endif
    float3 shadedColor = shading_frag(base.rgb, light_atten, N, V, L, i.uv, i.world_pos);
    float glow = tex2D(_GlowTex, TRANSFORM_TEX(i.uv, _GlowTex)).r;
    return float4(shadedColor, glow * _Glow);
}

#ifdef FURSTEP
float _FurLength;
float _FurDensity;
float _FurThinness;

float4 _ForceGlobal;
float4 _ForceLocal;

sampler2D _FurTex;

v2f vert_fur (appdata_full v)
{
    v2f o;
    float3 P = v.vertex.xyz + v.normal * _FurLength * 0.05 * FURSTEP;
    P += clamp(mul(unity_WorldToObject, _ForceGlobal).xyz + _ForceLocal.xyz, -1, 1) * pow(FURSTEP, 3) * _FurLength;
    o.pos = UnityObjectToClipPos(float4(P, 1.0));
    o.uv = v.texcoord;
    o.world_normal = normalize(UnityObjectToWorldNormal(v.normal));
    o.world_pos = mul(unity_ObjectToWorld, v.vertex);
    TRANSFER_VERTEX_TO_FRAGMENT(o);
    return o;
}

float hash12(float2 p)
{
	float3 p3  = frac(float3(p.xyx) * float3(.1031,.11369,.13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}

float4 frag_fur(v2f i): SV_Target
{
    float3 N = normalize(i.world_normal);
    float3 V = normalize(_WorldSpaceCameraPos - i.world_pos.xyz);
    float3 L = normalize(_WorldSpaceLightPos0.xyz);
    float4 base = tex2D(_Tex, TRANSFORM_TEX(i.uv, _Tex));
    if(base.a < 0.8)
        discard;

    float3 noise = tex2D(_FurTex, i.uv * _FurThinness).rgb;
    float alpha = clamp(noise * 1.2 - 
    (FURSTEP * FURSTEP + FURSTEP * 0.2) * _FurDensity,
    0, 1);
    if( alpha < 0.44 )
        discard;
    float r = hash12(i.uv.xy * 5);
    if(r > alpha)
        discard;

    base.rgb = base.rgb * lerp(0.95, 1, pow(FURSTEP,0.5));
    float light_atten = LIGHT_ATTENUATION(i);
    float3 shadedColor = shading_frag(base.rgb, light_atten, N, V, L);

    return float4(shadedColor, 0);
}
#endif