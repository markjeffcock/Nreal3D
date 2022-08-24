// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// Unlit shader. Simplest possible textured shader.
// - no lighting
// - no lightmap support
// - no per-material color

Shader "Unlit/Texture Stereo" {
Properties {
	[Enum(Side by Side, 0, Over Under, 1, Separate Images, 2)] _Layout("3D Mode", Float) = 0
    [NoScaleOffset] _MainTex ("Main/Left Texture", 2D) = "white" {}
	[NoScaleOffset] _MainTexR ("Right Texture (only use when using separate images)", 2D) = "white" {}
	[MaterialToggle] _Swap ("Swap Eyes", Float) = 0
}

SubShader {
    Tags { "RenderType"="Opaque" }
    LOD 100

    Pass {
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata_t {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D _MainTexR;
            float4 _MainTexR_ST;
			int _Layout;
			int _Swap;

            v2f vert (appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				int eyeIndex = _Swap ? 1 - unity_StereoEyeIndex : unity_StereoEyeIndex;
				fixed4 col;
				if (_Layout == 0) { // Side-by-Side
					col = tex2D(_MainTex, float2(i.texcoord.x * 0.5 + eyeIndex * 0.5, i.texcoord.y));
				}
				else if (_Layout == 1) { // Over-Under
					col = tex2D(_MainTex, float2(i.texcoord.x, i.texcoord.y * 0.5 + 0.5 - eyeIndex * 0.5));
				}
				else { // Separate
					if (!eyeIndex) {
						col = tex2D(_MainTex, i.texcoord);
					}
					else {
						col = tex2D(_MainTexR, i.texcoord);
					}
				}
				UNITY_APPLY_FOG(i.fogCoord, col);
				UNITY_OPAQUE_ALPHA(col.a);
				return col;
            }
        ENDCG
    }
}

}
