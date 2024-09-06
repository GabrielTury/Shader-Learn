// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
 
// nome do shader que aparece no material
Shader "Unlit/Flag"
{
    Properties
    {
        // textura que aparece no material _nome nome da variavel 
        //("coisa", tipo) nome que aparece no editor, tipo da variavel = inicializacao
        _MainTex ("Texture", 2D) = "white" {}
        _Amplitude ("Amplitude", float) = 1
        _Speed ("Speed", float) = 1 
        _WaveLength ("WaveLength", float) =1 
    }
    // bloco de codigo que define o comportamento do shader
    SubShader
    {
        // tags que definem o comportamento do shader
        Tags { "RenderType"="Opaque" }
        //define o lod deste subshader para posterior uso (muito raro)
        LOD 100
        //pass é uma etapa de renderizacao do shader (pode ter mais de uma)
        Pass
        {
            //inicio do codigo do shader em CGprogram (parecido com HLSL)
            CGPROGRAM
            //vertex se refere a funcao que processa os vertices
            #pragma vertex vert
            //fragment se refere a funcao que processa os fragmentos
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
 
 
            #include "UnityCG.cginc"
 
            //struct que define os dados de entrada do vertex shader
            struct appdata
            {
                //variaveis de entrada de placa (semantica)
                //os tipod de semantica podem ser: POSITION, NORMAL, TEXCOORD0, TEXCOORD1, TEXCOORD2, TEXCOORD3, COLOR, TANGENT
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 color: COLOR;
            };
            //struct que define os dados de saida do vertex shader e entrada do fragment shader
            //TEXCOORD0 é a semantica da variavel uv
            //Os tipos podem ser TEXCOORD0, TEXCOORD1, TEXCOORD2, TEXCOORD3, COLOR ,SV_POSITION, POSITION ou NORMAL
            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };
            //variavel que define a textura do material
            //na unity o nome ser o mesmo do shaderlab referencia a variavel automaticamente
            sampler2D _MainTex;
            //variavel que define a transformacao da textura
            //na unity o _ST referencia automaticamente ao parametro de Tiling e Offset do material
            float4 _MainTex_ST;
            
            float _Amplitude;
            float _Speed;
            float _WaveLength;

            float waveFunction;
            float4 pos;

            //funcao que processa os vertices
            v2f vert (appdata vEnter)
            {
                v2f output;
                pos = vEnter.vertex;
                waveFunction = _Amplitude  * sin( _Speed * _Time + _WaveLength* pos.x);

                pos.y += waveFunction;
                //calcula o vertice da cordenada local para a cordenada de projecao e de mundo
                //output.vertex = UnityObjectToClipPos(vEnter.vertex);
                //pode ser feita dessa maneira tambem
                //as matrizes da unity podem ser UNITY_MATRIX_MVP , UNITY_MATRIX_MV, UNITY_MATRIX_V, UNITY_MATRIX_P
                output.vertex = UnityObjectToClipPos(pos);
               
                //passa a uv para o fragment shader
                //TRANSFORM_TEX é uma macro que transforma a uv de acordo com o tiling e offset
                output.uv = TRANSFORM_TEX(vEnter.uv, _MainTex);
                //passa a coordenada do vertice para o fog
                UNITY_TRANSFER_FOG(output,output.vertex);
                return output;
            }
            //funcao que processa os fragmentos
            //semantica SV_Target indica que a saida é o fragmento final
            fixed4 frag (v2f input) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, input.uv)/*cos(_Time.y)*/;
                // apply fog
                UNITY_APPLY_FOG(input.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}