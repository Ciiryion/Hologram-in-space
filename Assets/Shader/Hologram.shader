Shader "Custom/Hologram"
{
    Properties
    {
        [HDR] _MainColor ("Couleur", Color) = (2, 0.5, 0, 1)

        // Plus cette valeur est élevée, plus le contour est fin
        _OutlinesSharpness ("Nettete Contour", Range(1.0, 20.0)) = 8.0
        // Plus cette valeur est élevée, plus le contour est lumineux
        _OutlinesIntensity ("Luminosite Contour", Range(1.0, 10.0)) = 5.0

        // Plus cette valeur est élevée plus les scanlines vont rapidement du haut vers le bas
        // Si la valeur est négative les scanlines iront du bas vers le haut
        _ScanSpeed ("Vitesse Scanlines", Float) = 2.0
        
        _ScanDensity ("Densite Scanlines", Float) = 80.0
        _ScanIntensity ("Intensite Scanlines", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100

        ZWrite Off
        Blend One One
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 viewDir : TEXCOORD3;
                float3 normal : TEXCOORD4;
                float4 worldPos : TEXCOORD5;
            };

            fixed4 _MainColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _OutlinesSharpness;
            float _OutlinesIntensity;
            float _ScanSpeed;
            float _ScanDensity;
            float _ScanIntensity;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                // Direction de la caméra vers le pixel (utilise pour le Fresnel)
                o.viewDir = normalize(UnityWorldSpaceViewDir(o.worldPos));
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                // Calcul des outlines
                float NdotV = 1.0 - saturate(dot(i.normal, i.viewDir));
                float outlines = pow(NdotV, _OutlinesSharpness) * _OutlinesIntensity;

                // Calcul des scanlines
                float scan = sin(i.worldPos.y * _ScanDensity + _Time.y * _ScanSpeed);
                scan = smoothstep(0.2, 0.3, scan) * _ScanIntensity;

                // Ajout des outlines et scanlines pour le rendu final
                fixed3 finalColor = fixed3(0,0,0);
                finalColor += (col.rgb * _MainColor.rgb) * 0.1;
                finalColor += _MainColor.rgb * scan;
                finalColor += _MainColor.rgb * outlines;

                UNITY_APPLY_FOG(i.fogCoord, finalColor);
                
                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}