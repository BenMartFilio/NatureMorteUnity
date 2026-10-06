Shader "Fauve/PaintLitPP"
{
    Properties
    {
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        [MainColor] _BaseColor("Tint", Color) = (1,1,1,1)

        _OpacityMap("Opacity Map", 2D) = "white" {}
        _Opacity("Opacity", Range(0,1)) = 1

        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Strength", Range(0,1)) = 0.5
        _MetallicMap("Metallic Map", 2D) = "white" {}
        _Metallic("Metallic", Range(0,1)) = 0
        _RoughMap("Roughness Map", 2D) = "white" {}
        _Roughness("Roughness", Range(0,1)) = 0.6
        _Saturation("Saturation Boost", Range(0.5,2.5)) = 1.4

        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
        [Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 1
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull", Float) = 2
        [Toggle(_ALPHATEST_ON)] _AlphaClip("Alpha Clip", Float) = 0
        _Cutoff("Alpha Cutoff", Range(0,1)) = 0.5

        [Enum(ExactIrradiance,0,EstimatedFromFinalColor,1)] _PPMode("PP Emulation Mode", Float) = 0
        _Bands("Light Bands", Range(2,6)) = 3
        _BandSoft("Band Softness", Range(0.005,0.3)) = 0.06
        _BandKey("Band Key (irradiance of top band)", Range(0.2,4)) = 1.5
        _ShadowFloor("Shadow Floor", Range(0,0.6)) = 0.2
        _LightGain("Light Gain", Range(0,3)) = 1.2
        _ShadowTint("Shadow Tint", Color) = (0.55,0.45,0.95,1)
        _ShadowGain("Shadow Gain", Range(0,2)) = 1.0

        _SpecIntensity("Spec Intensity", Range(0,3)) = 1.0
        _EnvBands("Analytic Env Bands", Range(2,8)) = 4

        [Enum(Analytic,0,UnityProbe,1,CustomCubemap,2)] _EnvMode("Reflection Source", Float) = 1
        _ReflStrength("Reflection Strength", Range(0,3)) = 1
        _ReflSaturation("Reflection Saturation", Range(0,2.5)) = 1.3
        _ReflPosterize("Reflection Posterize Bands (0 = off)", Range(0,8)) = 0
        _ReflBrushWarp("Reflection Brush Warp", Range(0,0.5)) = 0.12
        _ReflMaxBright("Reflection Max Brightness", Range(1,20)) = 4
        _ReflMinBlur("Reflection Min Blur", Range(0,0.5)) = 0.12

        [Toggle(_LIQUID)] _Liquid("Liquid", Float) = 0
        _LiquidColor("Liquid Color", Color) = (0.55,0.05,0.15,1)
        _LiquidDensity("Liquid Density", Range(0,12)) = 3
        _LiquidScatter("Liquid Body Scatter", Range(0,1)) = 0.5

        _RimColor("Rim / Contour Color", Color) = (0.25,0.1,0.45,1)
        _RimPower("Rim Power", Range(0.5,8)) = 3
        _RimStrength("Rim Strength", Range(0,1)) = 0.5
        _OutlineColor("Outline Color", Color) = (0.12,0.05,0.25,1)
        _OutlineWidth("Outline Width ", Range(0,8)) = 2.5
        _StrokeScale("Stroke Density", Range(10,300)) = 70
        _StrokeStretch("Stroke Length", Range(1,12)) = 5
        _StrokeAngles("Stroke Angle Steps", Range(2,12)) = 6
        _StrokeBaseAngle("Base Angle", Range(-3.14,3.14)) = 0.6
        _StrokeFollowForm("Follow Form", Range(0,1)) = 0.8
        _BrushContrast("Brush Contrast", Range(0.5,4)) = 2.0
        _BrushColorVar("Brush Brightness Variation", Range(0,0.5)) = 0.15
        _BrushHueShift("Brush Warm/Cool Shift", Range(0,1)) = 0.5
        _BrushLightJitter("Brush Light Edge Jitter", Range(0,0.6)) = 0.25

        [Toggle(_REFRACT)] _Refract("Refraction", Float) = 0
        _RefractStrength("Refraction Strength", Range(0,0.2)) = 0.05
        _TintStrength("Glass Tint Strength", Range(0,1)) = 0.7
        _FresnelAlpha("Fresnel Opacity", Range(0,1)) = 0.6
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
        TEXTURE2D(_OpacityMap); SAMPLER(sampler_OpacityMap); //Pour les mesh qui ont différentes opacités comme la jar par exemple
        TEXTURE2D(_BumpMap); SAMPLER(sampler_BumpMap);
        TEXTURE2D(_MetallicMap); SAMPLER(sampler_MetallicMap);
        TEXTURE2D(_RoughMap); SAMPLER(sampler_RoughMap);

        float4 _Fauve_SkyColor;
        float4 _Fauve_HorizonColor;
        float4 _Fauve_GroundColor;
        float  _Fauve_AmbientIntensity;
        TEXTURECUBE(_Fauve_EnvCube); SAMPLER(sampler_Fauve_EnvCube);
        float  _Fauve_EnvIntensity;

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float _BumpScale, _Metallic, _Roughness, _Saturation, _Cutoff;
            float _Opacity;
            float _PPMode, _Bands, _BandSoft, _BandKey, _ShadowFloor, _LightGain, _ShadowGain;
            float4 _ShadowTint;
            float _SpecIntensity, _EnvBands;
            float _EnvMode, _ReflStrength, _ReflSaturation, _ReflPosterize, _ReflBrushWarp, _ReflMaxBright, _ReflMinBlur;
            float4 _LiquidColor;
            float _LiquidDensity, _LiquidScatter;
            float4 _RimColor, _OutlineColor;
            float _RimPower, _RimStrength, _OutlineWidth;
            float _StrokeScale, _StrokeStretch, _StrokeAngles, _StrokeBaseAngle, _StrokeFollowForm;
            float _BrushContrast, _BrushColorVar, _BrushHueShift, _BrushLightJitter;
            float _RefractStrength, _TintStrength, _FresnelAlpha;
        CBUFFER_END
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_Cull]

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _REFRACT
            #pragma shader_feature_local_fragment _LIQUID
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH

            #pragma multi_compile _ _FORWARD_PLUS _CLUSTER_LIGHT_LOOP
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_ATLAS
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float4 tangentWS : TEXCOORD3;
            };

            static const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

            float3 Sat(float3 c, float s)
            {
                float l = dot(c, LUMA);
                return lerp(l.xxx, c, s);
            }

            float PaintBands(float x, float bands, float soft)
            {
                float s = saturate(x) * bands;
                float sf = min(max(soft, fwidth(s) * 1.2), 0.5);
                float i = floor(s);
                float f = frac(s);
                float t = smoothstep(0.5 - sf, 0.5 + sf, f);
                return saturate((i + t) / bands);
            }

            float Hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            float VNoise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                float a = Hash21(i);
                float b = Hash21(i + float2(1, 0));
                float c = Hash21(i + float2(0, 1));
                float d = Hash21(i + float2(1, 1));
                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }

            float Stroke(float2 p, float angle)
            {
                float s, c;
                sincos(angle, s, c);
                float2 q = float2(c * p.x + s * p.y, -s * p.x + c * p.y);
                q.x /= _StrokeStretch;
                return VNoise(q) * 0.65 + VNoise(q * 2.7 + 13.1) * 0.35;
            }

            float3 PaintEnv(float3 R, float3 L, float3 lightColor)
            {
                float h = PaintBands(R.y * 0.5 + 0.5, _EnvBands, 0.12);
                float3 c = lerp(_Fauve_GroundColor.rgb, _Fauve_HorizonColor.rgb, smoothstep(0.30, 0.45, h));
                c = lerp(c, _Fauve_SkyColor.rgb, smoothstep(0.50, 0.75, h));
                float sun = smoothstep(0.93, 0.95, dot(R, L));
                return lerp(c, lightColor * 1.5, sun);
            }

            void AccumLight(Light light, float3 N, float3 V, float rough, float3 F0,
                            inout float3 irr, inout float3 specAcc)
            {
                float3 L = light.direction;
                float ndl = saturate(dot(N, L));
                float atten = light.distanceAttenuation * light.shadowAttenuation;
                float3 radiance = light.color * _LightGain * atten * ndl;
                irr += radiance;

                float3 H = normalize(L + V);
                float nh = saturate(dot(N, H));
                float lh = saturate(dot(L, H));
                float r  = max(rough * rough, 0.0064);
                float r2 = r * r;
                float d  = nh * nh * (r2 - 1.0) + 1.0001;
                float spec = r2 / (d * d * max(0.1, lh * lh) * (r * 4.0 + 2.0));
                float3 Fl = F0 + (1.0 - F0) * pow(1.0 - lh, 5.0);
                specAcc += spec * Fl * radiance * _SpecIntensity;
            }

            float3 SampleEnv(float3 R, float3 L, float3 lightColor, float rough, float3 positionWS, float2 suv)
            {
                rough = max(rough, _ReflMinBlur);
                float3 e;
                if (_EnvMode < 0.5)
                {
                    e = PaintEnv(R, L, lightColor);
                }
                else if (_EnvMode < 1.5)
                {
                    e = GlossyEnvironmentReflection(R, positionWS, rough, 1.0h, suv);
                }
                else
                {
                    float mip = PerceptualRoughnessToMipmapLevel(rough);
                    e = SAMPLE_TEXTURECUBE_LOD(_Fauve_EnvCube, sampler_Fauve_EnvCube, R, mip).rgb * _Fauve_EnvIntensity;
                }

                e = e / (1.0 + e / _ReflMaxBright);
                e = Sat(e, _ReflSaturation);

                if (_ReflPosterize > 0.5)
                {
                    float l  = max(dot(e, LUMA), 1e-4);
                    float t  = l / (1.0 + l);
                    float tq = min(PaintBands(t, _ReflPosterize, 0.1), 0.98);
                    e *= (tq / (1.0 - tq)) / l;
                }
                return e * _ReflStrength;
            }

            Varyings vert(Attributes v)
            {
                Varyings o;
                VertexPositionInputs p = GetVertexPositionInputs(v.positionOS.xyz);
                VertexNormalInputs n = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.positionCS = p.positionCS;
                o.positionWS = p.positionWS;
                o.normalWS = n.normalWS;
                o.tangentWS = float4(n.tangentWS, v.tangentOS.w * GetOddNegativeScale());
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                return o;
            }

            float4 frag(Varyings i, FRONT_FACE_TYPE facing : FRONT_FACE_SEMANTIC) : SV_Target
            {
                float4 baseTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv) * _BaseColor;
                float opacityTex = SAMPLE_TEXTURE2D(_OpacityMap, sampler_OpacityMap, i.uv).r;
                float alpha = baseTex.a * opacityTex * _Opacity;
                #if defined(_ALPHATEST_ON)
                    clip(alpha - _Cutoff);
                #endif
                float metallic = saturate(SAMPLE_TEXTURE2D(_MetallicMap, sampler_MetallicMap, i.uv).r * _Metallic);
                float rough = saturate(SAMPLE_TEXTURE2D(_RoughMap, sampler_RoughMap, i.uv).r * _Roughness);

                float3 nWS = normalize(i.normalWS) * IS_FRONT_VFACE(facing, 1.0, -1.0);
                float3 tWS = normalize(i.tangentWS.xyz);
                float3 bWS = cross(nWS, tWS) * i.tangentWS.w;
                float3 nTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.uv), _BumpScale);
                float3 N = normalize(TransformTangentToWorld(nTS, half3x3(tWS, bWS, nWS)));
                {
                    float3 dNdx = ddx(N);
                    float3 dNdy = ddy(N);
                    float variance = 0.25 * (dot(dNdx, dNdx) + dot(dNdy, dNdy));
                    rough = sqrt(saturate(rough * rough + min(2.0 * variance, 0.18)));
                }

                float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                Light mainLight = GetMainLight(shadowCoord, i.positionWS, half4(1,1,1,1));
                float3 L = mainLight.direction;
                float3 V = GetWorldSpaceNormalizeViewDir(i.positionWS);
                float2 suv = GetNormalizedScreenSpaceUV(i.positionCS);

                float2 sp = i.positionCS.xy / _ScreenParams.y;
                float3 Nv = TransformWorldToViewDir(N);
                float raw = atan2(Nv.y, Nv.x) + PI * 0.5;
                float stp = PI / _StrokeAngles;
                float qa = floor(raw / stp + 0.5) * stp;
                float w = saturate(length(Nv.xy) * 3.0) * _StrokeFollowForm;
                float ang = lerp(_StrokeBaseAngle, qa, w);
                float b = Stroke(sp * _StrokeScale, ang);
                b = saturate((b - 0.5) * _BrushContrast + 0.5);

                float3 albedo = Sat(baseTex.rgb, _Saturation);
                albedo *= 1.0 + (b - 0.5) * 2.0 * _BrushColorVar;
                albedo += (b - 0.5) * _BrushHueShift * float3(0.10, 0.02, -0.10);
                albedo = max(albedo, 0);

                float3 F0 = lerp(float3(0.04, 0.04, 0.04), albedo, metallic);

                float3 ambient = lerp(_Fauve_GroundColor.rgb, _Fauve_SkyColor.rgb, N.y * 0.5 + 0.5) * _Fauve_AmbientIntensity;

                float3 irr = 0;
                float3 specAcc = 0;
                AccumLight(mainLight, N, V, rough, F0, irr, specAcc);

                #if defined(_ADDITIONAL_LIGHTS)
                    InputData inputData = (InputData)0;
                    inputData.positionWS = i.positionWS;
                    inputData.normalizedScreenSpaceUV = suv;
                    half4 shadowMask = half4(1,1,1,1);
                    #if USE_FORWARD_PLUS
                    [loop] for (uint fl = 0; fl < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); fl++)
                    {
                        Light al = GetAdditionalLight(fl, i.positionWS, shadowMask);
                        AccumLight(al, N, V, rough, F0, irr, specAcc);
                    }
                    #endif

                    uint pixelLightCount = GetAdditionalLightsCount();
                    LIGHT_LOOP_BEGIN(pixelLightCount)
                        Light al = GetAdditionalLight(lightIndex, i.positionWS, shadowMask);
                        AccumLight(al, N, V, rough, F0, irr, specAcc);
                    LIGHT_LOOP_END
                #endif

                float  NdV = saturate(dot(N, V));
                float3 R = reflect(-V, N);
                R = normalize(R + (b - 0.5) * _ReflBrushWarp * (tWS - bWS));
                float3 F = F0 + (1.0 - F0) * pow(1.0 - NdV, 5.0);
                float3 env = SampleEnv(R, L, mainLight.color, rough, i.positionWS, suv);
                float3 refl = env * F * (1.0 - rough * 0.8);
                float3 surfLayer = specAcc + refl;

                float3 irradiance = ambient + irr;
                float3 sceneC = albedo * irradiance * (1.0 - metallic) + surfLayer; 

                float3 Eest = (_PPMode > 0.5) ? sceneC / max(albedo, 0.05) : irradiance;
                float lE = dot(Eest, LUMA);
                float t = saturate(lE / _BandKey) + (b - 0.5) * _BrushLightJitter;
                float band = PaintBands(t, _Bands, _BandSoft);
                float3 Eb = Eest * (_BandKey * lerp(_ShadowFloor, 1.0, band) / max(lE, 1e-3));
                Eb *= lerp(_ShadowTint.rgb * _ShadowGain, float3(1,1,1), band);

                float3 diffuse = albedo * Eb * (1.0 - metallic);
                float3 litSurf = (_PPMode > 0.5) ? albedo * Eb : diffuse + surfLayer;

                float NdVg = saturate(dot(nWS, V));
                float rimMask = PaintBands(pow(1.0 - NdVg, _RimPower), 2, 0.15) * _RimStrength;

                alpha = saturate(alpha + F.g * _FresnelAlpha);

                float3 col;
                #if defined(_REFRACT)
                    float2 dist = (Nv.xy + (b - 0.5) * 0.5) * _RefractStrength;
                    float3 bg = SampleSceneColor(suv + dist);

                    #if defined(_LIQUID)
                        float3 lc   = max(Sat(_LiquidColor.rgb, _Saturation), 1e-3);
                        float  path = _LiquidDensity / max(NdV, 0.25);
                        float3 T    = pow(lc, path);
                        float3 lDiff = lc * Eb;
                        float scatter = saturate((1.0 - dot(T, float3(0.3333, 0.3333, 0.3333))) * _LiquidScatter);
                        col = lerp(bg * T, lDiff, scatter) + surfLayer;
                    #else
                        bg *= lerp(float3(1,1,1), Sat(baseTex.rgb, _Saturation), _TintStrength);
                        col = lerp(bg, litSurf, alpha);
                    #endif
                    alpha = 1.0;
                #else
                    col = litSurf;
                #endif

                col = lerp(col, _RimColor.rgb, rimMask);
                if (any(isnan(col)) || any(isinf(col))) col = 0;
                col = clamp(col, 0.0, 16.0);
                return float4(col, alpha);
            }
            ENDHLSL
        }

        Pass
        {
            Name "Outline"
            Tags { "LightMode"="SRPDefaultUnlit" }
            Cull Front
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vertO
            #pragma fragment fragO
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            struct AttrO {float4 positionOS : POSITION; float3 normalOS : NORMAL; float2 uv : TEXCOORD0;};
            struct VaryO {float4 positionCS : SV_POSITION; float2 uv : TEXCOORD0;};

            VaryO vertO(AttrO v)
            {
                VaryO o;
                float3 pWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 nWS = TransformObjectToWorldNormal(v.normalOS);
                float4 cs = TransformWorldToHClip(pWS);
                float2 nCS = mul((float3x3)UNITY_MATRIX_VP, nWS).xy;
                nCS = normalize(nCS + 1e-5);
                cs.xy += nCS / _ScreenParams.xy * _OutlineWidth * cs.w * 2.0;
                if (_OutlineWidth <= 0.001) cs = float4(2, 2, 2, 1);
                o.positionCS = cs;
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                return o;
            }

            float4 fragO(VaryO i) : SV_Target
            {
                #if defined(_ALPHATEST_ON)
                    float baseAlpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv).a * _BaseColor.a;
                    float opacity = SAMPLE_TEXTURE2D(_OpacityMap, sampler_OpacityMap, i.uv).r * _Opacity;
                    clip(baseAlpha * opacity - _Cutoff);
                #endif
                return float4(_OutlineColor.rgb, 1);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
            ZWrite On ZTest LEqual ColorMask 0
            Cull [_Cull]

            HLSLPROGRAM
            #pragma vertex vertS
            #pragma fragment fragS
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            float3 _LightDirection;
            float3 _LightPosition;

            struct AttrS {float4 positionOS : POSITION; float3 normalOS : NORMAL; float2 uv : TEXCOORD0;};
            struct VaryS {float4 positionCS : SV_POSITION; float2 uv : TEXCOORD0;};

            VaryS vertS(AttrS v)
            {
                VaryS o;
                float3 pWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 nWS = TransformObjectToWorldNormal(v.normalOS);
                #if defined(_CASTING_PUNCTUAL_LIGHT_SHADOW)
                    float3 ldir = normalize(_LightPosition - pWS);
                #else
                    float3 ldir = _LightDirection;
                #endif
                float4 cs = TransformWorldToHClip(ApplyShadowBias(pWS, nWS, ldir));
                #if UNITY_REVERSED_Z
                    cs.z = min(cs.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    cs.z = max(cs.z, UNITY_NEAR_CLIP_VALUE);
                #endif
                o.positionCS = cs;
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                return o;
            }

            float4 fragS(VaryS i) : SV_Target
            {
                #if defined(_ALPHATEST_ON)
                    float baseAlpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv).a * _BaseColor.a;
                    float opacity = SAMPLE_TEXTURE2D(_OpacityMap, sampler_OpacityMap, i.uv).r * _Opacity;
                    clip(baseAlpha * opacity - _Cutoff);
                #endif
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }
            ZWrite On ColorMask 0
            Cull [_Cull]

            HLSLPROGRAM
            #pragma vertex vertD
            #pragma fragment fragD
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            struct AttrD {float4 positionOS : POSITION; float2 uv : TEXCOORD0;};
            struct VaryD {float4 positionCS : SV_POSITION; float2 uv : TEXCOORD0;};

            VaryD vertD(AttrD v)
            {
                VaryD o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                return o;
            }

            float4 fragD(VaryD i) : SV_Target
            {
                #if defined(_ALPHATEST_ON)
                    float baseAlpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv).a * _BaseColor.a;
                    float opacity = SAMPLE_TEXTURE2D(_OpacityMap, sampler_OpacityMap, i.uv).r * _Opacity;
                    clip(baseAlpha * opacity - _Cutoff);
                #endif
                return 0;
            }
            ENDHLSL
        }
    }
    FallBack Off
}
