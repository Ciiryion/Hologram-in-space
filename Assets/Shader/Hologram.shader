Shader "Custom/Hologram"
{
    Properties
    {
        // Paramètre du centre de l'hologramme
        [Header(Base Color Settings)]
        _MainColor ("Base Color", Color) = (1, 0, 0, 1)
        _CenterFalloff ("Center Falloff", Range(1.0, 20.0)) = 5.0

        // Paramètres du contour
        [Header(Rim Color Settings)]
        _RimColor ("Rim Color", Color) = (0, 1, 0, 1)
        _RimThickness ("Rim Thickness", Range(1, 2.0)) = 1
        _FlashAmplitude ("Flash Amplitude", Range(0,1)) = 0.5

        // Paramètres des scanlines. La vitesse va du haut vers le bas, valeur négative pour l'inverse
        [Header(Scanlines)]
        _ScanSpeed ("Scanlines Speed", Float) = 2.0
        _ScanDensity ("Scanlines Density", Float) = 80.0
        _ScanIntensity ("Scanlines Intensity", Range(0, 1)) = 0.5

        // Paramètres du glitch aléatoire
        [Header(Random Glitch)]
        _GlitchFrequency ("Glitch Frequency", Range(0, 50)) = 10.0
        _GlitchThreshold ("Glitch Chance", Range(0, 1)) = 0.1
        _GlitchIntensity ("Glitch Intensity", Range(0, 2)) = 0.2

        // Paramètres de l'impact avec une balle
        [Header(Impact)]
        _HitPosition ("Hit Position", Vector) = (0,0,0,0)
        _HitStrength ("Hit Strength", Range(0,1)) = 0.0 // Animé par script
        _HitRadius ("Hit Radius", Float) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }

        ZWrite Off
        Blend SrcAlpha One
        Cull Back

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata { float4 vertex : POSITION; float3 normal : NORMAL; };

            struct v2f {
                float4 vertex : SV_POSITION; float3 worldNormal : TEXCOORD0; float3 viewDir : TEXCOORD1;
                float3 worldPos : TEXCOORD3; float glitchState : TEXCOORD4;
            };

            float4 _MainColor, _RimColor, _HitPosition;
            float _CenterFalloff, _RimThickness, _FlashAmplitude, _HitStrength, _HitRadius;
            float _ScanSpeed, _ScanDensity, _ScanIntensity, _GlitchFrequency, _GlitchThreshold, _GlitchIntensity;

            // Rrenvoie un chiffre chaotique entre 0 et 1 pour simuler l'aléatoire'
            float randomNoise(float2 seed) { return frac(sin(dot(seed, float2(12.9898, 78.233))) * 43758.5453); }

            v2f vert (appdata v)
            {
                v2f o;

                // Calcul du glitch
                float timeStep = floor(_Time.y * _GlitchFrequency);
                float isGlitching = step(1.0 - _GlitchThreshold, randomNoise(float2(timeStep, timeStep)));

                // Deformation du maillage
                float randomOffset = randomNoise(float2(timeStep * 1.5, v.vertex.y));
                v.vertex.xyz += float3(randomOffset - 0.5, 0, 0) * _GlitchIntensity * isGlitching;;

                // Alimentation des variables nécessaires
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.glitchState = isGlitching;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 N = normalize(i.worldNormal), V = normalize(i.viewDir);
                float NdotV = saturate(dot(N, V));

                // Calcul du centre de l'objet
                float3 centerBase = _MainColor.rgb * pow(NdotV, _CenterFalloff);

                // Calcul du contour de l'objet avec un effet de clignotement
                float flash = _RimThickness + sin(_Time.y * 100) * _FlashAmplitude;
                float3 rimEffect = _RimColor.rgb * pow(1.0 - NdotV, 1.0 / max(0.001, flash));

                // Calcul des scanlines
                float scanLinesPos = i.worldPos.y * _ScanDensity + _Time.y * _ScanSpeed;
                float scanLinesPattern = (sin(scanLinesPos) + 1.0) * 0.5;
                float scanLines = lerp(1.0, scanLinesPattern, _ScanIntensity);
                
                // Calcul de l'Impact
                float d = distance(i.worldPos, _HitPosition.xyz);
                float ripple = (sin(d * 50.0 - _Time.y * 50.0) + 1.0) * 0.5;
                float3 impactEffect = _RimColor * smoothstep(_HitRadius, 0, d) * ripple * _HitStrength * 5.0;

                // Assemblage
                float3 finalRGB = (centerBase + rimEffect) * scanLines + impactEffect;
                float baseAlpha = max(pow(NdotV, _CenterFalloff) * _MainColor.a, pow(1.0 - NdotV, 1.0 / max(0.001, flash)) * _RimColor.a);

                // Pendant un glitch, l'hologramme devient un peu plus opaque
                float glitchAlpha = max(baseAlpha, i.glitchState * 0.8);

                // Rend opaque là où il y a un impact
                float finalAlpha = max(glitchAlpha, _HitStrength * smoothstep(_HitRadius, 0, d));
                
                return fixed4(finalRGB, finalAlpha);
            }
            ENDCG
        }
    }
}