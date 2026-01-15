Shader "Custom/Hologram"
{
    Properties
    {
        [Header(Base Color Settings)]
        _MainColor ("Base Color", Color) = (1, 0, 0, 1)
        // Plus cette valeur est élevée, plus la couleur reste concentrée au centre
        _CenterFalloff ("Center Falloff", Range(1.0, 20.0)) = 5.0

        [Header(Rim Color Settings)]
        // Couleur du contour
        _RimColor ("Rim Color", Color) = (0, 1, 0, 1)
        // Puissance de l'effet (Plus c'est bas, plus le contour est fin)
        _RimThickness ("Rim Thickness", Range(0.05, 3.0)) = 0.5

        // Paramètres des scanlines. La vitesse va du haut vers le bas, valeur négative pour l'inverse
        [Header(Scanlines)]
        _ScanSpeed ("Scanlines Speed", Float) = 2.0
        _ScanDensity ("Scanlines Density", Float) = 80.0
        _ScanIntensity ("Scanlines Intensity", Range(0, 1)) = 0.5
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

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
                float3 worldPos : TEXCOORD3;
            };

            float4 _MainColor;
            float _CenterFalloff;
            float4 _RimColor;
            float _RimThickness;

            float _ScanSpeed;
            float _ScanDensity;
            float _ScanIntensity;

            v2f vert (appdata v)
            {
                v2f o;
                // Alimentation des variables nécessaires
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 N = normalize(i.worldNormal);
                float3 V = normalize(i.viewDir);
                float NdotV = saturate(dot(N, V));

                // Calcul du centre de l'objet
                float centerMask = pow(NdotV, _CenterFalloff);
                float3 centerBase = _MainColor.rgb * centerMask;

                // Calcul du contour de l'objet
                float invertedPower = 1.0 / max(_RimThickness, 0.001);
                float rimMask = pow(1.0 - NdotV, invertedPower);
                float3 rimEffect = _RimColor.rgb * rimMask;

                // Addition des deux composantes précédentes
                float3 finalRGB = centerBase + rimEffect;

                // Calcul de l'alpha
                float finalAlpha = max(centerMask * _MainColor.a, rimMask * _RimColor.a);

                // Calcul et ajout des scanlines
                float scanLinesPos = i.worldPos.y * _ScanDensity + _Time.y * _ScanSpeed;
                float scanLinesPattern = (sin(scanLinesPos) + 1.0) * 0.5;
                float scanLines = lerp(1.0, scanLinesPattern, _ScanIntensity);
                finalRGB *= scanLines;

                return fixed4(finalRGB, finalAlpha);
            }
            ENDCG
        }
    }
}