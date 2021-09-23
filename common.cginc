#define RGB2LUM float3(0.3, 0.55, 0.15)
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

float3 SHLightMax(float3 col[6]) {
	float3 ocol;
	ocol =            col[0];
	ocol = max(ocol , col[1]);
	ocol = max(ocol , col[2]);
	ocol = max(ocol , col[3]);
	ocol = max(ocol , col[4]);
	ocol = max(ocol , col[5]);

	return ocol;
}

float3 SHLightMin(float3 col[6]) {
	return (col[0] + col[1] + col[2] + col[3] + col[4] + col[5]) * 0.166667f; // 0.166667 = 1/6
}

float3 SHLightDirection(float len[6]) {
	return normalize(float3(len[1] - len[0] , len[3] - len[2] , len[5] - len[4]));
}

float3 shadeLightProb(float3 N)
{
    // from SunaoShader
    // float3 SHColor[6];
    // SHColor[0]   = ShadeSH9(float4(-1.0f ,  0.0f ,  0.0f , 1.0f));
    // SHColor[1]   = ShadeSH9(float4( 1.0f ,  0.0f ,  0.0f , 1.0f));
    // SHColor[2]   = ShadeSH9(float4( 0.0f , -1.0f ,  0.0f , 1.0f));
    // SHColor[3]   = ShadeSH9(float4( 0.0f ,  1.0f ,  0.0f , 1.0f));
    // SHColor[4]   = ShadeSH9(float4( 0.0f ,  0.0f , -1.0f , 1.0f));
    // SHColor[5]   = ShadeSH9(float4( 0.0f ,  0.0f ,  1.0f , 1.0f));

    // float SHLength[6];
    // SHLength[0]  = dot(RGB2LUM, SHColor[0]);
    // SHLength[1]  = dot(RGB2LUM, SHColor[1]);
    // SHLength[2]  = dot(RGB2LUM, SHColor[2]);
    // SHLength[3]  = dot(RGB2LUM, SHColor[3]) + 0.000001f;
    // SHLength[4]  = dot(RGB2LUM, SHColor[4]);
    // SHLength[5]  = dot(RGB2LUM, SHColor[5]);

    // float3 shdir      = SHLightDirection(SHLength);
    // float3 shmax      = SHLightMax(SHColor);
    // float3 shmin      = SHLightMin(SHColor);

    // float3 ambient = lerp(shmin, shmax, dot(shdir, N));

    return ShadeSH9(float4(0.0.xxx, 1));
}

float3 GetDefaultLightDirection()
{
    return normalize(UNITY_MATRIX_V[2].xyz * -1 + UNITY_MATRIX_V[1].xyz*0.5);
}

float3 GetDefaultLightColor()
{
    return lerp(ShadeSH9(float4(0.0.xxx,1)),0.95,1);
}

float square(float f)
{
    return f * f;
}

void GetLightAmbient(float3 N, out float3 L, out float3 lightColor, out float3 ambient)
{
    float anyLXYZ = any(_WorldSpaceLightPos0.xyz);
    L = normalize(lerp(GetDefaultLightDirection(), _WorldSpaceLightPos0.xyz, anyLXYZ));
    lightColor = lerp(GetDefaultLightColor(), _LightColor0.rgb, anyLXYZ);
    ambient = shadeLightProb(N);
}

float3 GetPixelAmbient(float3 world_pos)
{
    float3 pixelAmbient = 0;
    [unroll]
    for(int i = 0; i < 4; i++)
    {
        float4 color = unity_LightColor[i];
        float3 wPos = float3(unity_4LightPosX0[i], unity_4LightPosY0[i], unity_4LightPosZ0[i]);
        float3 tolight = wPos - world_pos;

        float range = (0.005 * sqrt(1000000 - unity_4LightAtten0[i])) / sqrt(unity_4LightAtten0[i]);
        float dis = max(1e-4f, length(tolight));
        float att = 1 - clamp(dis / range , 0, 1);
        pixelAmbient += pow(color.rgb * att * clamp(color.w, 0, 10), 0.454545);
    }
    pixelAmbient = clamp(pow(pixelAmbient, 2.2), 0, 1);
    return pixelAmbient;
}

float3 transformHS(float3 from, float3 to, float factor, float toSEnch = 2.0)
{
    float3 fromHSV = RGBtoHSV(from);
    float3 toHSV = RGBtoHSV(to);
    float3 mediumHSV = float3(
    toHSV.x,
    max(0.1, saturate(toHSV.y * toSEnch)),
    fromHSV.z
    );
    float3 medium = HSVtoRGB(mediumHSV);
    return lerp(
    from,
    medium,
    factor * pow(saturate(toHSV.y), 0.5) * pow(saturate(0.25 + toHSV.z), 0.2)
    );
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

float blinnphong(float3 L,float3 N,float3 V,float g)
{
    float3 H = normalize(L + V);
    float specular = pow(max(0.0, dot(H, N)), square(max(0.01, 1/max(0.01, g))) );
    return specular;
}

float3 shading_frag(float3 base, float3 light_color, float light_atten, float3 ambient, float3 pixelAmbient, float3 N, float3 V, float3 L, float2 uv = 0, float4 world_pos = 0)
{
    ambient = max(0.001, ambient);
    float lumEnv = saturate(dot(ambient,RGB2LUM));
    float lum = clamp(dot(light_color,RGB2LUM), 0.2, 1);

    light_color = RGBtoHSV(light_color);
    light_color.z = 1.0;
    const float maxSaturate = 0.35;
    lum *= lerp(1, 1.8, pow((1/maxSaturate) * max(0, light_color.y-maxSaturate),3));
    light_color.y = min(maxSaturate, light_color.y);
    light_color = HSVtoRGB(light_color);

    lumEnv = lumEnv * 0.8 + lum * 0.2;
    lum = clamp(lum, lumEnv * 1.2, lumEnv * 1.5);

    float HL = 0.5 + 0.5 * dot(N, L);
    float _SystemShadowsLevel_var = (light_atten*0.5)+0.5 > 0.001 ? (light_atten*0.5)+0.5 : 0.0001;
    float biasedHL = (HL*saturate(_SystemShadowsLevel_var) ) - _ShadowOffset;

    float NV = saturate(dot(N,V));
    float4 sky_data = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflect(-V, N), 8 * _SpecularSmooth);   
    float3 sky_color = DecodeHDR (sky_data, unity_SpecCube0_HDR);
    float sky_lum = dot(RGB2LUM, sky_color);
    float specularMask = tex2D(_SpecularMaskTex, TRANSFORM_TEX(uv, _SpecularMaskTex)).r;
    base = lerp(
        base * lerp(1, 0.82, specularMask * _Metallic),
        base * min(1.1, sky_lum * 1.2 + 0.7),
        specularMask * _Metallic * lerp(1, 0.2, pow(NV,5)));

    _Rim = pow(_Rim, 4);
    #ifdef FURSTEP
        float rim = saturate((pow(1-NV,lerp(1,10,_RimSharpness)) - lerp(1,0.0,_Rim)) * lerp(5,20,_RimSharpness));
        float Occlusion = lerp( 0 , 1.15, pow(FURSTEP*1.175, 5));
        rim = min(rim, Occlusion);
        base.rgb *= lerp(1,2,max(0, rim - 1));
    #else
        float rim = saturate((pow(1-NV,lerp(4,5,_RimSharpness)) - lerp(1,0.0,pow(_Rim,0.1))) * lerp(5,50,_RimSharpness));
        rim *= saturate(dot(N,float3(0,1,0))*0.8 + 0.8);
    #endif

    #ifdef __IsStocking
        float3 body = tex2D(_BodyTex, TRANSFORM_TEX(uv, _BodyTex)).xyz;
        //float TDfactor = saturate(fwidth(uv) / fwidth(world_pos.xyz) * _TextureDensity);
        float stckfactor = saturate(pow(NV,_StockingPow)*_StockingStrength + _StockingBase);
        stckfactor *= tex2D(_BodyMask, TRANSFORM_TEX(uv, _BodyMask)).r;
        base = lerp(base, body, stckfactor);
    #endif

    // chroma
    float3 tilebaseL = transformHS(base.rgb, ambient, 0.25 - lum * 0.12) * light_color;
    float3 tilebaseS = transformHS(base.rgb, ambient, 0.45 - _ShadowBrightness * 0.15) * lerp(light_color, 1, 0.3);
    // luminance
    tilebaseL = tilebaseL * lum;
    tilebaseS = tilebaseS * lumEnv;

    float baseSat = _Saturate * 0.7 * saturate((0.85 - lum)*4);
    float3 tilebaseLHSV = RGBtoHSV(tilebaseL);
    tilebaseLHSV.y = saturate(tilebaseLHSV.y * (1 + baseSat));
    tilebaseL = HSVtoRGB(tilebaseLHSV);

    float3 tilebaseSHSV = RGBtoHSV(tilebaseS);
    tilebaseSHSV.y = saturate(tilebaseSHSV.y * (1 + _Saturate + baseSat) + _Saturate / 4.0);
    tilebaseS = HSVtoRGB(tilebaseSHSV);

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
        float atten = lerp(min(light_atten, biasedHL), face_light_attenuation, min(lightMapMask, lightMap.y));
    #else
        float atten = min(light_atten, biasedHL);
    #endif

    atten = max(atten, lerp(rim, atten, saturate((lum - lumEnv - 0.3) * 1.5)));
    float shadowBrightness = 0.9 + 0.1 * _ShadowBrightness;
    float3 shadowedColor = tilebaseS * shadowBrightness * _ShadowColor;

    float shadowFactor = saturate((atten * 2 - 0.2) * lerp(1, 250, _ShadowSharpness * _ShadowSharpness));
    float3 shadedColor = lerp(shadowedColor, tilebaseL, shadowFactor);

    #ifdef FURSTEP
        shadedColor *= saturate(0.68 + square(FURSTEP + 0.1));
    #endif
    #ifdef __IsSSS
        float curvature = 1 - tex2D(_CurvatureMap, TRANSFORM_TEX(uv, _CurvatureMap)).r;
        float _atten = (HL * saturate(_SystemShadowsLevel_var) ) - (_ShadowOffset+0.15);
        _atten =min(1-light_atten, -_atten);
        _atten = ((_atten - 0.5) * 0.8) + 0.5;
        float SSS_shadow_factor = (_atten * 2 + 0.1) * lerp(2, 0.5, _SSS_Depth);
        float SSS_factor = min(0.4 , Guassian(SSS_shadow_factor) * smoothstep(0,1,curvature));
        SSS_factor = pow(SSS_factor, 0.8);
        #ifdef __IsStocking
            SSS_factor *= stckfactor;
        #endif
        shadedColor = shadedColor * lerp(1, _SSS_Color, SSS_factor * _SSS_Strength * 3);
    #endif

    float specular = (
        blinnphong(L,N,V, _SpecularSmooth)
    )
    * _SpecularStrength * sky_lum;

    float3 pixelAmbientHSV = RGBtoHSV(pixelAmbient);
    pixelAmbientHSV = max(1e-5, pixelAmbientHSV);
    float3 brightPixelAmbient = HSVtoRGB(float3(pixelAmbientHSV.x, pow(pixelAmbientHSV.y, 0.6), 1));
    float3 shiftedShadedColor = shadedColor *  
        lerp(1,
            brightPixelAmbient,
            pow(dot(pixelAmbient,RGB2LUM) * 0.7, 0.5)
        );
    shadedColor = light_color * specular * specularMask * atten + shiftedShadedColor;

    shadedColor = RGBtoHSV(shadedColor);
    shadedColor.z = clamp(0, 1.1, pow(pow(shadedColor.z,1/2.2) + pow(pixelAmbientHSV.z,1/2.2) * 0.4,2.2));
    shadedColor = HSVtoRGB(shadedColor);
    return shadedColor;
}

float hash12(float2 p)
{
	float3 p3  = frac(float3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}