Shader "Unlit_Transparent_Fresnel_Liquid_Level_With_Moving_Bubbles"
{
    Properties
    {
        _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        _BubbleTex ("Bubble Texture", 2D) = "white" {}
        _FresnelPower ("Fresnel Power", Range(0.0, 10.0)) = 1.0
        _FresnelIntensity ("Fresnel Intensity", Range(0.0, 10.0)) = 1.0
        _LiquidLevel ("Liquid Level", Range(0.0, 2.0)) = 0.0
        _WaveSpeed ("Wave Speed", Range(0.0, 500.0)) = 1.0
        _WaveHeight ("Wave Height", Range(0.0, 0.1)) = 0.1
        _WaveFrequency ("Wave Frequency", Range(0.0, 100.0)) = 1.0
        _BubbleIntensity ("Bubble Intensity", Range(0.0, 1.0)) = 0.5
        _BubbleScale ("Bubble Scale", Range(0.1, 10.0)) = 1.0
        _BubbleSpeed ("Bubble Speed", Range(-5.0, 5.0)) = 1.0
        _Color("Color", Color) = (1,1,1,1)
        _AbsolutePositionY("Absolute Position Y", Range(-1000.0, 1000.0)) = 0.0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
        LOD 100

        ZWrite Off
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata_t {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float worldPosY : TEXCOORD2;
                UNITY_FOG_COORDS(3)
            };

            sampler2D _MainTex;
            sampler2D _BubbleTex;
            float4 _MainTex_ST;
            float4 _BubbleTex_ST;
            float _FresnelPower;
            float _FresnelIntensity;
            float _LiquidLevel;
            float4 _Color;
            float _WaveSpeed;
            float _WaveHeight;
            float _WaveFrequency;
            float _BubbleIntensity;
            float _BubbleScale;
            float _BubbleSpeed;
            float _AbsolutePositionY;

            // Vertex Shader
            v2f vert(appdata_t v)
            {
                v2f o;

                // Apply wave distortion
                float waveOffset = sin(v.texcoord.x * _WaveFrequency + _Time * _WaveSpeed) * _WaveHeight;

                // Transform vertex position to clip space
                o.vertex = UnityObjectToClipPos(v.vertex);

                // Transform normal to world space for fresnel effect
                o.worldNormal = normalize(mul((float3x3)unity_WorldToObject, v.normal));

                // Calculate world position Y
                o.worldPosY = mul(unity_ObjectToWorld, v.vertex).y + waveOffset;

                // Texture coordinates
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            // Fragment Shader
            fixed4 frag(v2f i) : SV_Target
            {
                // Sample the main texture
                fixed4 col = tex2D(_MainTex, i.texcoord) * _Color;

                // Compute the Fresnel effect
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.vertex.xyz);
                float fresnel = pow(1.0 - max(0.0, dot(i.worldNormal, viewDir)), _FresnelPower);

                // Add Fresnel highlights
                float4 fresnelColor = _FresnelIntensity * fresnel * fixed4(1.0, 1.0, 1.0, 1.0);
                col += fresnelColor;

                // Handle liquid level
                if (i.worldPosY < _AbsolutePositionY - _LiquidLevel)
                {
                    // Offset bubble UVs to simulate upward motion
                    float2 bubbleUV = i.texcoord * _BubbleScale;
                    bubbleUV.y += frac(_Time.y * _BubbleSpeed); // Cycles the bubbles upwards

                    // Sample bubble texture for the liquid area
                    fixed4 bubbleColor = tex2D(_BubbleTex, bubbleUV) * _BubbleIntensity;

                    // Mix bubbles into the liquid
                    col.rgb = lerp(col.rgb, bubbleColor.rgb, bubbleColor.a);
                    col.a = 0.5;
                }
                else
                {
                    col.a = 0.0;
                }

                // Apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                return col;
            }

            ENDCG
        }
    }
}