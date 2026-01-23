// Toony Colors Pro+Mobile 2
// (c) 2014-2025 Jean Moreno

Shader "Toony Colors Pro 2/User/Water_Shader"
{
	Properties
	{
		[Enum(Front, 2, Back, 1, Both, 0)] _Cull ("Render Face", Float) = 2.0
		[TCP2ToggleNoKeyword] _ZWrite ("Depth Write", Float) = 1.0
		[HideInInspector] _RenderingMode ("rendering mode", Float) = 0.0
		[HideInInspector] _SrcBlend ("blending source", Float) = 1.0
		[HideInInspector] _DstBlend ("blending destination", Float) = 0.0
		[TCP2Separator]

		[TCP2HeaderHelp(Base)]
		_BaseColor ("Color", Color) = (1,1,1,1)
		[TCP2ColorNoAlpha] _HColor ("Highlight Color", Color) = (0.75,0.75,0.75,1)
		[TCP2ColorNoAlpha] _SColor ("Shadow Color", Color) = (0.2,0.2,0.2,1)
		[MainTexture] _BaseMap ("Albedo", 2D) = "white" {}
		_Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5
		[TCP2Separator]

		[TCP2Header(Ramp Shading)]
		
		_RampThreshold ("Threshold", Range(0.01,1)) = 0.5
		_RampSmoothing ("Smoothing", Range(0.001,1)) = 0.5
		[TCP2Separator]
		
		[TCP2HeaderHelp(Normal Mapping)]
		[Toggle(_NORMALMAP)] _UseNormalMap ("Enable Normal Mapping", Float) = 0
		[NoScaleOffset] _BumpMap ("Normal Map", 2D) = "bump" {}
		_BumpScale ("Scale", Float) = 1
		[TCP2Separator]
		
		[TCP2HeaderHelp(Sketch)]
		[Toggle(TCP2_SKETCH)] _UseSketch ("Enable Sketch Effect", Float) = 0
		_ProgressiveSketchTexture ("Progressive Texture", 2D) = "black" {}
		_ProgressiveSketchSmoothness ("Progressive Smoothness", Range(0.005,0.5)) = 0.1
		[TCP2Separator]
		
		[TCP2HeaderHelp(Vertex Waves Animation)]
		_WavesSpeed ("Speed", Float) = 2
		_WavesHeight ("Height", Float) = 0.1
		_WavesFrequency ("Frequency", Range(0,10)) = 1
		
		[TCP2HeaderHelp(Depth Based Effects)]
		[TCP2ColorNoAlpha] _DepthColor ("Depth Color", Color) = (0,0,1,1)
		[PowerSlider(5.0)] _DepthColorDistance ("Depth Color Distance", Range(0.01,3)) = 0.5
		[PowerSlider(5.0)] _DepthAlphaDistance ("Depth Alpha Distance", Range(0.01,10)) = 0.5
		_DepthAlphaMin ("Depth Alpha Min", Range(0,1)) = 0.5
		_FoamSpread ("Foam Spread", Range(0,5)) = 2
		_FoamStrength ("Foam Strength", Range(0,1)) = 0.8
		_FoamColor ("Foam Color (RGB) Opacity (A)", Color) = (0.9,0.9,0.9,1)
		_FoamTex ("Foam Texture", 2D) = "black" {}
		_FoamSpeed ("Foam Speed", Vector) = (2,2,2,2)
		_FoamSmoothness ("Foam Smoothness", Range(0,0.5)) = 0.02
		
		[TCP2HeaderHelp(Outline)]
		_OutlineWidth ("Width", Range(0.1,4)) = 1
		_OutlineColorVertex ("Color", Color) = (0,0,0,1)
		// Outline Normals
		[TCP2MaterialKeywordEnumNoPrefix(Regular, _, Vertex Colors, TCP2_COLORS_AS_NORMALS, Tangents, TCP2_TANGENT_AS_NORMALS, UV1, TCP2_UV1_AS_NORMALS, UV2, TCP2_UV2_AS_NORMALS, UV3, TCP2_UV3_AS_NORMALS, UV4, TCP2_UV4_AS_NORMALS)]
		_NormalsSource ("Outline Normals Source", Float) = 0
		[TCP2MaterialKeywordEnumNoPrefix(Full XYZ, TCP2_UV_NORMALS_FULL, Compressed XY, _, Compressed ZW, TCP2_UV_NORMALS_ZW)]
		_NormalsUVType ("UV Data Type", Float) = 0
		[TCP2Separator]
		[TCP2Vector4Floats(Contrast X,Contrast Y,Contrast Z,Smoothing,1,16,1,16,1,16,0.05,10)] _TriplanarSamplingStrength ("Triplanar Sampling Parameters", Vector) = (8,8,8,0.5)

		[ToggleOff(_RECEIVE_SHADOWS_OFF)] _ReceiveShadowsOff ("Receive Shadows", Float) = 1

		// Avoid compile error if the properties are ending with a drawer
		[HideInInspector] __dummy__ ("unused", Float) = 0
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalPipeline"
			"RenderType"="TransparentCutout"
			"Queue"="AlphaTest"
		}

		HLSLINCLUDE
		#define fixed half
		#define fixed2 half2
		#define fixed3 half3
		#define fixed4 half4

		#if UNITY_VERSION >= 202020
			#define URP_10_OR_NEWER
		#endif
		#if UNITY_VERSION >= 202120
			#define URP_12_OR_NEWER
		#endif
		#if UNITY_VERSION >= 202220
			#define URP_14_OR_NEWER
		#endif

		// Texture/Sampler abstraction
		#define TCP2_TEX2D_WITH_SAMPLER(tex)						TEXTURE2D(tex); SAMPLER(sampler##tex)
		#define TCP2_TEX2D_NO_SAMPLER(tex)							TEXTURE2D(tex)
		#define TCP2_TEX2D_SAMPLE(tex, samplertex, coord)			SAMPLE_TEXTURE2D(tex, sampler##samplertex, coord)
		#define TCP2_TEX2D_SAMPLE_LOD(tex, samplertex, coord, lod)	SAMPLE_TEXTURE2D_LOD(tex, sampler##samplertex, coord, lod)

		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

		// Uniforms

		// Shader Properties
		TCP2_TEX2D_WITH_SAMPLER(_BumpMap);
		TCP2_TEX2D_WITH_SAMPLER(_BaseMap);
		TCP2_TEX2D_WITH_SAMPLER(_FoamTex);
		TCP2_TEX2D_WITH_SAMPLER(_ProgressiveSketchTexture);
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

		CBUFFER_START(UnityPerMaterial)
			
			// Shader Properties
			float _WavesFrequency;
			float _WavesHeight;
			float _WavesSpeed;
			float _OutlineWidth;
			fixed4 _OutlineColorVertex;
			float _BumpScale;
			float4 _BaseMap_ST;
			float _Cutoff;
			fixed4 _BaseColor;
			fixed4 _DepthColor;
			float _DepthColorDistance;
			float _FoamSpread;
			float _FoamStrength;
			fixed4 _FoamColor;
			float4 _FoamSpeed;
			float4 _FoamTex_ST;
			float _FoamSmoothness;
			float _DepthAlphaDistance;
			float _DepthAlphaMin;
			float _RampThreshold;
			float _RampSmoothing;
			float4 _ProgressiveSketchTexture_ST;
			float _ProgressiveSketchSmoothness;
			fixed4 _SColor;
			fixed4 _HColor;
			float4 _TriplanarSamplingStrength;
		CBUFFER_END

		// Texture sampling with triplanar UVs
		float4 tex2D_triplanar(sampler2D samp, float4 tiling_offset, float3 worldPos, float3 worldNormal)
		{
			half4 sample_y = ( tex2D(samp, worldPos.xz * tiling_offset.xy + tiling_offset.zw).rgba );
			half4 sample_x = ( tex2D(samp, worldPos.zy * tiling_offset.xy + tiling_offset.zw).rgba );
			half4 sample_z = ( tex2D(samp, worldPos.xy * tiling_offset.xy + tiling_offset.zw).rgba );
			
			// blending
			half3 blendWeights = pow(abs(worldNormal), _TriplanarSamplingStrength.xyz / _TriplanarSamplingStrength.w);
			blendWeights = blendWeights / (blendWeights.x + abs(blendWeights.y) + blendWeights.z);
			half4 triplanar = sample_x * blendWeights.x + sample_y * blendWeights.y + sample_z * blendWeights.z;
			
			return triplanar;
		}
			
		// Version with separate texture and sampler
		#define TCP2_TEX2D_SAMPLE_TRIPLANAR(tex, samplertex, tiling, positionWS, normalWS) tex2D_triplanar(tex, sampler##samplertex, tiling, positionWS, normalWS)
		float4 tex2D_triplanar(Texture2D tex, SamplerState samp, float4 tiling_offset, float3 worldPos, float3 worldNormal)
		{
			half4 sample_y = ( tex.Sample(samp, worldPos.xz * tiling_offset.xy + tiling_offset.zw).rgba );
			half4 sample_x = ( tex.Sample(samp, worldPos.zy * tiling_offset.xy + tiling_offset.zw).rgba );
			half4 sample_z = ( tex.Sample(samp, worldPos.xy * tiling_offset.xy + tiling_offset.zw).rgba );
			
			// blending
			half3 blendWeights = pow(abs(worldNormal), _TriplanarSamplingStrength.xyz / _TriplanarSamplingStrength.w);
			blendWeights = blendWeights / (blendWeights.x + abs(blendWeights.y) + blendWeights.z);
			half4 triplanar = sample_x * blendWeights.x + sample_y * blendWeights.y + sample_z * blendWeights.z;
			
			return triplanar;
		}
		
		// Built-in renderer (CG) to SRP (HLSL) bindings
		#define UnityObjectToClipPos TransformObjectToHClip
		#define _WorldSpaceLightPos0 _MainLightPosition
		
		ENDHLSL

		// Outline Include
		HLSLINCLUDE

		struct appdata_outline
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			#if TCP2_UV1_AS_NORMALS
			float4 texcoord0 : TEXCOORD0;
		#elif TCP2_UV2_AS_NORMALS
			float4 texcoord1 : TEXCOORD1;
		#elif TCP2_UV3_AS_NORMALS
			float4 texcoord2 : TEXCOORD2;
		#elif TCP2_UV4_AS_NORMALS
			float4 texcoord3 : TEXCOORD3;
		#endif
		#if TCP2_COLORS_AS_NORMALS
			float4 vertexColor : COLOR;
		#endif
			float4 tangent : TANGENT;
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		struct v2f_outline
		{
			float4 vertex : SV_POSITION;
			float4 screenPosition : TEXCOORD0;
			float4 vcolor : TEXCOORD1;
			UNITY_VERTEX_INPUT_INSTANCE_ID
			UNITY_VERTEX_OUTPUT_STEREO
		};

		v2f_outline vertex_outline (appdata_outline v)
		{
			v2f_outline output = (v2f_outline)0;

			UNITY_SETUP_INSTANCE_ID(v);
			UNITY_TRANSFER_INSTANCE_ID(v, output);
			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

			// Shader Properties Sampling
			float __wavesFrequency = ( _WavesFrequency );
			float __wavesHeight = ( _WavesHeight );
			float __wavesSpeed = ( _WavesSpeed );
			float __outlineWidth = ( _OutlineWidth );
			float4 __outlineColorVertex = ( _OutlineColorVertex.rgba );

			// Vertex water waves
			float _waveFrequency = __wavesFrequency;
			float _waveHeight = __wavesHeight;
			float3 _vertexWavePos = v.vertex.xyz * _waveFrequency;
			float _phase = _Time.y * __wavesSpeed;
			float waveFactorX = sin(_vertexWavePos.x + _phase) * _waveHeight;
			float waveFactorZ = sin(_vertexWavePos.z + _phase) * _waveHeight;
			v.vertex.y += (waveFactorX + waveFactorZ);
			
		#ifdef TCP2_COLORS_AS_NORMALS
			//Vertex Color for Normals
			float3 normal = (v.vertexColor.xyz*2) - 1;
		#elif TCP2_TANGENT_AS_NORMALS
			//Tangent for Normals
			float3 normal = v.tangent.xyz;
		#elif TCP2_UV1_AS_NORMALS || TCP2_UV2_AS_NORMALS || TCP2_UV3_AS_NORMALS || TCP2_UV4_AS_NORMALS
			#if TCP2_UV1_AS_NORMALS
				#define uvChannel texcoord0
			#elif TCP2_UV2_AS_NORMALS
				#define uvChannel texcoord1
			#elif TCP2_UV3_AS_NORMALS
				#define uvChannel texcoord2
			#elif TCP2_UV4_AS_NORMALS
				#define uvChannel texcoord3
			#endif
		
			#if TCP2_UV_NORMALS_FULL
			//UV for Normals, full
			float3 normal = v.uvChannel.xyz;
			#else
			//UV for Normals, compressed
			#if TCP2_UV_NORMALS_ZW
				#define ch1 z
				#define ch2 w
			#else
				#define ch1 x
				#define ch2 y
			#endif
			float3 n;
			//unpack uvs
			v.uvChannel.ch1 = v.uvChannel.ch1 * 255.0/16.0;
			n.x = floor(v.uvChannel.ch1) / 15.0;
			n.y = frac(v.uvChannel.ch1) * 16.0 / 15.0;
			//- get z
			n.z = v.uvChannel.ch2;
			//- transform
			n = n*2 - 1;
			float3 normal = n;
			#endif
		#else
			float3 normal = v.normal;
		#endif
		
		#if TCP2_ZSMOOTH_ON
			//Correct Z artefacts
			normal = UnityObjectToViewPos(normal);
			normal.z = -_ZSmooth;
		#endif
			float size = 1;
		
		#if !defined(SHADOWCASTER_PASS)
			output.vertex = UnityObjectToClipPos(v.vertex.xyz + normal * __outlineWidth * size * 0.01);
		#else
			v.vertex = v.vertex + float4(normal,0) * __outlineWidth * size * 0.01;
		#endif
		
			output.vcolor.xyzw = __outlineColorVertex;
			float4 clipPos = output.vertex;

			// Screen Position
			float4 screenPos = ComputeScreenPos(clipPos);
			output.screenPosition = screenPos;

			return output;
		}

		float4 fragment_outline (v2f_outline input) : SV_Target
		{

			UNITY_SETUP_INSTANCE_ID(input);
			UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

			// Shader Properties Sampling
			float4 __outlineColor = ( float4(1,1,1,1) );

			half4 outlineColor = __outlineColor * input.vcolor.xyzw;

			return outlineColor;
		}

		ENDHLSL
		// Outline Include End
		Pass
		{
			Name "Main"
			Tags
			{
				"LightMode"="UniversalForward"
			}
		Blend [_SrcBlend] [_DstBlend]
		Cull [_Cull]
		ZWrite [_ZWrite]

			HLSLPROGRAM
			// Required to compile gles 2.0 with standard SRP library
			// All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 3.0

			// -------------------------------------
			// Material keywords
			#pragma shader_feature_local _ _RECEIVE_SHADOWS_OFF

			// -------------------------------------
			// Universal Render Pipeline keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH

			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ _CLUSTER_LIGHT_LOOP
			#include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"

			// -------------------------------------

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing

			#pragma vertex Vertex
			#pragma fragment Fragment

			//--------------------------------------
			// Toony Colors Pro 2 keywords
		#pragma shader_feature_local _ _ALPHAPREMULTIPLY_ON
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local_fragment TCP2_SKETCH

			// vertex input
			struct Attributes
			{
				float4 vertex       : POSITION;
				float3 normal       : NORMAL;
				float4 tangent      : TANGENT;
				float4 texcoord0 : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			// vertex output / fragment input
			struct Varyings
			{
				float4 positionCS     : SV_POSITION;
				float3 normal         : NORMAL;
				float4 worldPosAndFog : TEXCOORD0;
			#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord    : TEXCOORD1; // compute shadow coord per-vertex for the main light
			#endif
			#ifdef _ADDITIONAL_LIGHTS_VERTEX
				half3 vertexLights : TEXCOORD2;
			#endif
				float4 screenPosition : TEXCOORD3;
				float3 pack1 : TEXCOORD4; /* pack1.xyz = tangent */
				float3 pack2 : TEXCOORD5; /* pack2.xyz = bitangent */
				float2 pack3 : TEXCOORD6; /* pack3.xy = texcoord0 */
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#if USE_FORWARD_PLUS || USE_CLUSTER_LIGHT_LOOP
				// Fake InputData struct needed for Forward+ macro
				struct InputDataForwardPlusDummy
				{
					float3  positionWS;
					float2  normalizedScreenSpaceUV;
				};
			#endif

			Varyings Vertex(Attributes input)
			{
				Varyings output = (Varyings)0;

				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				// Texture Coordinates
				output.pack3.xy.xy = input.texcoord0.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
				// Shader Properties Sampling
				float __wavesFrequency = ( _WavesFrequency );
				float __wavesHeight = ( _WavesHeight );
				float __wavesSpeed = ( _WavesSpeed );

				float3 worldPos = mul(UNITY_MATRIX_M, input.vertex).xyz;
				
				// Vertex water waves
				float _waveFrequency = __wavesFrequency;
				float _waveHeight = __wavesHeight;
				float3 _vertexWavePos = input.vertex.xyz * _waveFrequency;
				float _phase = _Time.y * __wavesSpeed;
				float waveFactorX = sin(_vertexWavePos.x + _phase) * _waveHeight;
				float waveFactorZ = sin(_vertexWavePos.z + _phase) * _waveHeight;
				input.vertex.y += (waveFactorX + waveFactorZ);
				
				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.vertex.xyz);
			#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				output.shadowCoord = GetShadowCoord(vertexInput);
			#endif
				float4 clipPos = vertexInput.positionCS;

				float4 screenPos = ComputeScreenPos(clipPos);
				output.screenPosition.xyzw = screenPos;

				VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normal, input.tangent);
			#ifdef _ADDITIONAL_LIGHTS_VERTEX
				// Vertex lighting
				output.vertexLights = VertexLighting(vertexInput.positionWS, vertexNormalInput.normalWS);
			#endif

				// world position
				output.worldPosAndFog = float4(vertexInput.positionWS.xyz, 0);

				// normal
				output.normal = normalize(vertexNormalInput.normalWS);

				// tangent
				output.pack1.xyz = vertexNormalInput.tangentWS;
				output.pack2.xyz = vertexNormalInput.bitangentWS;

				// clip position
				output.positionCS = vertexInput.positionCS;

				return output;
			}

			half4 Fragment(Varyings input
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				float3 positionWS = input.worldPosAndFog.xyz;
				float3 normalWS = normalize(input.normal);
				half3 tangentWS = input.pack1.xyz;
				half3 bitangentWS = input.pack2.xyz;
				#if defined(_NORMALMAP)
				half3x3 tangentToWorldMatrix = half3x3(tangentWS.xyz, bitangentWS.xyz, normalWS.xyz);
				#endif

				// Shader Properties Sampling
				float4 __normalMap = ( TCP2_TEX2D_SAMPLE(_BumpMap, _BumpMap, input.pack3.xy).rgba );
				float __bumpScale = ( _BumpScale );
				float4 __albedo = ( TCP2_TEX2D_SAMPLE(_BaseMap, _BaseMap, input.pack3.xy).rgba );
				float4 __mainColor = ( _BaseColor.rgba );
				float __alpha = ( __albedo.a * __mainColor.a );
				float __cutoff = ( _Cutoff );
				float3 __depthColor = ( _DepthColor.rgb );
				float __depthColorDistance = ( _DepthColorDistance );
				float __foamSpread = ( _FoamSpread );
				float __foamStrength = ( _FoamStrength );
				float4 __foamColor = ( _FoamColor.rgba );
				float4 __foamSpeed = ( _FoamSpeed.xyzw );
				float2 __foamTextureBaseUv = ( input.pack3.xy.xy );
				float __foamMask = ( .0 );
				float __foamSmoothness = ( _FoamSmoothness );
				float __depthAlphaDistance = ( _DepthAlphaDistance );
				float __depthAlphaMin = ( _DepthAlphaMin );
				float __ambientIntensity = ( 1.0 );
				float __rampThreshold = ( _RampThreshold );
				float __rampSmoothing = ( _RampSmoothing );
				float4 __progressiveSketchTexture = ( TCP2_TEX2D_SAMPLE_TRIPLANAR(_ProgressiveSketchTexture, _ProgressiveSketchTexture, float4(1, 1, 1, 1) * _ProgressiveSketchTexture_ST, positionWS, normalWS).rgba );
				float __progressiveSketchSmoothness = ( _ProgressiveSketchSmoothness );
				float3 __shadowColor = ( _SColor.rgb );
				float3 __highlightColor = ( _HColor.rgb );

				#if defined(_NORMALMAP)
				half4 normalMap = __normalMap;
				half3 normalTS = UnpackNormalScale(normalMap, __bumpScale);
					#if defined(_NORMALMAP)
				normalWS = normalize( mul(normalTS, tangentToWorldMatrix) );
					#endif
				#endif

				// Sample depth texture and calculate difference with local depth
				float sceneDepth = SampleSceneDepth(input.screenPosition.xyzw.xy / input.screenPosition.xyzw.w);
				if (unity_OrthoParams.w > 0.0)
				{
					// Orthographic camera
					#if UNITY_REVERSED_Z
						sceneDepth = ((_ProjectionParams.z - _ProjectionParams.y) * (1.0 - sceneDepth) + _ProjectionParams.y);
					#else
						sceneDepth = ((_ProjectionParams.z - _ProjectionParams.y) * (sceneDepth) + _ProjectionParams.y);
					#endif
				}
				else
				{
					// Perspective camera
					sceneDepth = LinearEyeDepth(sceneDepth, _ZBufferParams);
				}
				
				float localDepth = LinearEyeDepth(positionWS.xyz, GetWorldToViewMatrix());
				float depthDiff = abs(sceneDepth - localDepth);

				// main texture
				half3 albedo = __albedo.rgb;
				half alpha = __alpha;

				half3 emission = half3(0,0,0);
				// Alpha Testing
				half cutoffValue = __cutoff;
				clip(alpha - cutoffValue);
				
				albedo *= __mainColor.rgb;
				
				// Depth-based color
				half3 depthColor = __depthColor;
				half3 depthColorDist = __depthColorDistance;
				albedo.rgb = lerp(depthColor, albedo.rgb, saturate(depthColorDist * depthDiff));
				
				// Depth-based water foam
				half foamSpread = __foamSpread;
				half foamStrength = __foamStrength;
				half4 foamColor = __foamColor;
				
				half4 foamSpeed = __foamSpeed;
				float2 foamUV = __foamTextureBaseUv;
				
				float2 foamUV1 = foamUV.xy + _Time.yy * foamSpeed.xy * 0.05;
				half3 foam = ( TCP2_TEX2D_SAMPLE(_FoamTex, _FoamTex, foamUV1 * _FoamTex_ST.xy + _FoamTex_ST.zw).rgb );
				
				foamUV.xy += _Time.yy * foamSpeed.zw * 0.05;
				half3 foam2 = ( TCP2_TEX2D_SAMPLE(_FoamTex, _FoamTex, foamUV * _FoamTex_ST.xy + _FoamTex_ST.zw).rgb );
				
				foam = (foam + foam2) / 2.0;
				float foamDepth = saturate(foamSpread * depthDiff) * (1.0 - __foamMask);
				half foamSmooth = __foamSmoothness;
				half foamTerm = (smoothstep(foam.r - foamSmooth, foam.r + foamSmooth, saturate(foamStrength - foamDepth)) * saturate(1 - foamDepth)) * foamColor.a;
				albedo.rgb = lerp(albedo.rgb, foamColor.rgb, foamTerm);
				alpha = lerp(alpha, foamColor.a, foamTerm);
				
				// Depth-based alpha
				alpha *= saturate((__depthAlphaDistance * depthDiff) + __depthAlphaMin);

				// main light: direction, color, distanceAttenuation, shadowAttenuation
			#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord = input.shadowCoord;
			#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
				float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
			#else
				float4 shadowCoord = float4(0, 0, 0, 0);
			#endif

			#if defined(URP_10_OR_NEWER)
				#if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
					half4 shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
				#elif !defined (LIGHTMAP_ON)
					half4 shadowMask = unity_ProbesOcclusion;
				#else
					half4 shadowMask = half4(1, 1, 1, 1);
				#endif

				Light mainLight = GetMainLight(shadowCoord, positionWS, shadowMask);
			#else
				Light mainLight = GetMainLight(shadowCoord);
			#endif

			#if defined(_SCREEN_SPACE_OCCLUSION) || defined(USE_FORWARD_PLUS) || defined(USE_CLUSTER_LIGHT_LOOP)
				float2 normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
			#endif

				// ambient or lightmap
				// Samples SH fully per-pixel. SampleSHVertex and SampleSHPixel functions
				// are also defined in case you want to sample some terms per-vertex.
				half3 bakedGI = SampleSH(normalWS);
				half occlusion = 1;

				half3 indirectDiffuse = bakedGI;
				indirectDiffuse *= occlusion * albedo * __ambientIntensity;

				half3 lightDir = mainLight.direction;
				half3 lightColor = mainLight.color.rgb;

				half atten = mainLight.shadowAttenuation * mainLight.distanceAttenuation;

				half ndl = dot(normalWS, lightDir);
				half3 ramp;
				
				half rampThreshold = __rampThreshold;
				half rampSmooth = __rampSmoothing * 0.5;
				ndl = saturate(ndl);
				ramp = smoothstep(rampThreshold - rampSmooth, rampThreshold + rampSmooth, ndl);

				// apply attenuation
				ramp *= atten;

				half3 color = half3(0,0,0);
				half3 accumulatedRamp = ramp * max(lightColor.r, max(lightColor.g, lightColor.b));
				half3 accumulatedColors = ramp * lightColor.rgb;

				// Additional lights loop
			#ifdef _ADDITIONAL_LIGHTS
				uint pixelLightCount = GetAdditionalLightsCount();

				#if USE_FORWARD_PLUS || USE_CLUSTER_LIGHT_LOOP
					// Additional directional lights in Forward+
					for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
					{
						CLUSTER_LIGHT_LOOP_SUBTRACTIVE_LIGHT_CHECK

						Light light = GetAdditionalLight(lightIndex, positionWS, shadowMask);

						#if defined(_LIGHT_LAYERS)
							if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
						#endif
						{
							half atten = light.shadowAttenuation * light.distanceAttenuation;

							#if defined(_LIGHT_LAYERS)
								half3 lightDir = half3(0, 1, 0);
								half3 lightColor = half3(0, 0, 0);
								if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
								{
									lightColor = light.color.rgb;
									lightDir = light.direction;
								}
							#else
								half3 lightColor = light.color.rgb;
								half3 lightDir = light.direction;
							#endif

							half ndl = dot(normalWS, lightDir);
							half3 ramp;
							
							ndl = saturate(ndl);
							ramp = smoothstep(rampThreshold - rampSmooth, rampThreshold + rampSmooth, ndl);

							// apply attenuation (shadowmaps & point/spot lights attenuation)
							ramp *= atten;

							accumulatedRamp += ramp * max(lightColor.r, max(lightColor.g, lightColor.b));
							accumulatedColors += ramp * lightColor.rgb;

						}
					}

					// Data with dummy struct used in Forward+ macro (LIGHT_LOOP_BEGIN)
					InputDataForwardPlusDummy inputData;
					inputData.normalizedScreenSpaceUV = normalizedScreenSpaceUV;
					inputData.positionWS = positionWS;
				#endif

				LIGHT_LOOP_BEGIN(pixelLightCount)
				{
					#if defined(URP_10_OR_NEWER)
						Light light = GetAdditionalLight(lightIndex, positionWS, shadowMask);
					#else
						Light light = GetAdditionalLight(lightIndex, positionWS);
					#endif
					half atten = light.shadowAttenuation * light.distanceAttenuation;

					#if defined(_LIGHT_LAYERS)
						half3 lightDir = half3(0, 1, 0);
						half3 lightColor = half3(0, 0, 0);
						if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
						{
							lightColor = light.color.rgb;
							lightDir = light.direction;
						}
					#else
						half3 lightColor = light.color.rgb;
						half3 lightDir = light.direction;
					#endif

					half ndl = dot(normalWS, lightDir);
					half3 ramp;
					
					ndl = saturate(ndl);
					ramp = smoothstep(rampThreshold - rampSmooth, rampThreshold + rampSmooth, ndl);

					// apply attenuation (shadowmaps & point/spot lights attenuation)
					ramp *= atten;

					accumulatedRamp += ramp * max(lightColor.r, max(lightColor.g, lightColor.b));
					accumulatedColors += ramp * lightColor.rgb;

				}
				LIGHT_LOOP_END
			#endif
			#ifdef _ADDITIONAL_LIGHTS_VERTEX
				color += input.vertexLights * albedo;
			#endif

				accumulatedRamp = saturate(accumulatedRamp);
				
				// Sketch
				#if defined(TCP2_SKETCH)
				half4 sketch = __progressiveSketchTexture;
				half4 sketchWeights = half4(0,0,0,0);
				half sketchStep = 1.0 / 5.0;
				half sketchSmooth = __progressiveSketchSmoothness;
				sketchWeights.a = smoothstep(sketchStep + sketchSmooth, sketchStep - sketchSmooth, accumulatedRamp);
				sketchWeights.b = smoothstep(sketchStep*2 + sketchSmooth, sketchStep*2 - sketchSmooth, accumulatedRamp) - sketchWeights.a;
				sketchWeights.g = smoothstep(sketchStep*3 + sketchSmooth, sketchStep*3 - sketchSmooth, accumulatedRamp) - sketchWeights.a - sketchWeights.b;
				sketchWeights.r = smoothstep(sketchStep*4 + sketchSmooth, sketchStep*4 - sketchSmooth, accumulatedRamp) - sketchWeights.a - sketchWeights.b - sketchWeights.g;
				half combinedSketch = 1.0 - dot(sketch, sketchWeights);
				
				#endif
				half3 shadowColor = (1 - accumulatedRamp.rgb) * __shadowColor;
				accumulatedRamp = accumulatedColors.rgb * __highlightColor + shadowColor;
				color += albedo * accumulatedRamp;
				#if defined(TCP2_SKETCH)
				color.rgb *= combinedSketch;
				#endif

				// apply ambient
				color += indirectDiffuse;

				// Premultiply blending
				#if defined(_ALPHAPREMULTIPLY_ON)
					color.rgb *= alpha;
				#endif

				color += emission;

				return half4(color, alpha);
			}
			ENDHLSL
		}

		// Outline
		Pass
		{
			Name "Outline"
			Tags { "LightMode" = "Outline" }
			Tags
			{
			}
			Cull Front

			HLSLPROGRAM

			#pragma vertex vertex_outline
			#pragma fragment fragment_outline

			#pragma target 3.0

			#pragma multi_compile _ TCP2_COLORS_AS_NORMALS TCP2_TANGENT_AS_NORMALS TCP2_UV1_AS_NORMALS TCP2_UV2_AS_NORMALS TCP2_UV3_AS_NORMALS TCP2_UV4_AS_NORMALS
			#pragma multi_compile _ TCP2_UV_NORMALS_FULL TCP2_UV_NORMALS_ZW
			#pragma multi_compile_instancing

			ENDHLSL
		}
		// Depth & Shadow Caster Passes
		HLSLINCLUDE

		#if defined(SHADOW_CASTER_PASS) || defined(DEPTH_ONLY_PASS)

			#define fixed half
			#define fixed2 half2
			#define fixed3 half3
			#define fixed4 half4

			float3 _LightDirection;
			float3 _LightPosition;

			struct Attributes
			{
				float4 vertex   : POSITION;
				float3 normal   : NORMAL;
				float4 texcoord0 : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 positionCS     : SV_POSITION;
			#if defined(DEPTH_NORMALS_PASS)
				float3 normalWS : TEXCOORD0;
			#endif
				float4 screenPosition : TEXCOORD1;
				float2 pack1 : TEXCOORD2; /* pack1.xy = texcoord0 */
			#if defined(DEPTH_ONLY_PASS)
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			#endif
			};

			float4 GetShadowPositionHClip(Attributes input)
			{
				float3 positionWS = TransformObjectToWorld(input.vertex.xyz);
				float3 normalWS = TransformObjectToWorldNormal(input.normal);

				#if _CASTING_PUNCTUAL_LIGHT_SHADOW
					float3 lightDirectionWS = normalize(_LightPosition - positionWS);
				#else
					float3 lightDirectionWS = _LightDirection;
				#endif
				float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

				#if UNITY_REVERSED_Z
					positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#else
					positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#endif

				return positionCS;
			}

			Varyings ShadowDepthPassVertex(Attributes input)
			{
				Varyings output = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				#if defined(DEPTH_ONLY_PASS)
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
				#endif

				// Texture Coordinates
				output.pack1.xy.xy = input.texcoord0.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
				// Shader Properties Sampling
				float __wavesFrequency = ( _WavesFrequency );
				float __wavesHeight = ( _WavesHeight );
				float __wavesSpeed = ( _WavesSpeed );

				// Vertex water waves
				float _waveFrequency = __wavesFrequency;
				float _waveHeight = __wavesHeight;
				float3 _vertexWavePos = input.vertex.xyz * _waveFrequency;
				float _phase = _Time.y * __wavesSpeed;
				float waveFactorX = sin(_vertexWavePos.x + _phase) * _waveHeight;
				float waveFactorZ = sin(_vertexWavePos.z + _phase) * _waveHeight;
				input.vertex.y += (waveFactorX + waveFactorZ);
				
				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.vertex.xyz);

				// Screen Space UV
				float4 screenPos = ComputeScreenPos(vertexInput.positionCS);
				output.screenPosition.xyzw = screenPos;

				#if defined(DEPTH_ONLY_PASS)
					output.positionCS = TransformObjectToHClip(input.vertex.xyz);
					#if defined(DEPTH_NORMALS_PASS)
						float3 normalWS = TransformObjectToWorldNormal(input.normal);
						output.normalWS = normalWS; // already normalized in TransformObjectToWorldNormal
					#endif
				#elif defined(SHADOW_CASTER_PASS)
					output.positionCS = GetShadowPositionHClip(input);
				#else
					output.positionCS = float4(0,0,0,0);
				#endif

				return output;
			}

			half4 ShadowDepthPassFragment(
				Varyings input
	#if defined(DEPTH_NORMALS_PASS) && defined(_WRITE_RENDERING_LAYERS)
		#if UNITY_VERSION >= 60020000
				, out uint outRenderingLayers : SV_Target1
		#else
				, out float4 outRenderingLayers : SV_Target1
		#endif
	#endif
			) : SV_TARGET
			{
				#if defined(DEPTH_ONLY_PASS)
					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
				#endif

				// Shader Properties Sampling
				float4 __albedo = ( TCP2_TEX2D_SAMPLE(_BaseMap, _BaseMap, input.pack1.xy).rgba );
				float4 __mainColor = ( _BaseColor.rgba );
				float __alpha = ( __albedo.a * __mainColor.a );
				float __cutoff = ( _Cutoff );

				half3 albedo = half3(1,1,1);
				half alpha = __alpha;
				half3 emission = half3(0,0,0);
				// Alpha Testing
				half cutoffValue = __cutoff;
				clip(alpha - cutoffValue);

				#if defined(DEPTH_NORMALS_PASS)
					#if defined(_WRITE_RENDERING_LAYERS)
						#if UNITY_VERSION >= 60020000
							outRenderingLayers = EncodeMeshRenderingLayer();
						#else
							outRenderingLayers = float4(EncodeMeshRenderingLayer(GetMeshRenderingLayer()), 0, 0, 0);
						#endif
					#endif

					#if defined(URP_12_OR_NEWER)
						return float4(input.normalWS.xyz, 0.0);
					#else
						return float4(PackNormalOctRectEncode(TransformWorldToViewDir(input.normalWS, true)), 0.0, 0.0);
					#endif
				#endif

				return 0;
			}

		#endif
		ENDHLSL

		Pass
		{
			Name "ShadowCaster"
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			// using simple #define doesn't work, we have to use this instead
			#pragma multi_compile SHADOW_CASTER_PASS

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing
			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#pragma vertex ShadowDepthPassVertex
			#pragma fragment ShadowDepthPassFragment

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

			ENDHLSL
		}

		Pass
		{
			Name "DepthNormals"
			Tags
			{
				"LightMode" = "DepthNormals"
			}

			ZWrite On

			HLSLPROGRAM
			#pragma exclude_renderers gles gles3 glcore
			#pragma target 2.0

			#pragma multi_compile_instancing

			// using simple #define doesn't work, we have to use this instead
			#pragma multi_compile DEPTH_ONLY_PASS
			#pragma multi_compile DEPTH_NORMALS_PASS

			#pragma vertex ShadowDepthPassVertex
			#pragma fragment ShadowDepthPassFragment

			ENDHLSL
		}

		// Scene selection and picking passes
		Pass
		{
			Name "SceneSelectionPass"
			Tags
			{
				"LightMode" = "SceneSelectionPass"
			}

			Cull [_Cull]

			HLSLPROGRAM
			#pragma exclude_renderers gles gles3 glcore
			#pragma target 2.0

			#pragma multi_compile_instancing
			#pragma multi_compile DEPTH_ONLY_PASS

			#pragma vertex ShadowDepthPassVertex
			#pragma fragment SceneSelectionFragment

			int _ObjectId;
			int _PassValue;

			half4 SceneSelectionFragment(Varyings input) : SV_Target
			{
				ShadowDepthPassFragment(input);
				return float4(_ObjectId, _PassValue, 1, 1);
			}

			ENDHLSL
		}

		Pass
		{
			Name "ScenePickingPass"
			Tags
			{
				"LightMode" = "Picking"
			}

			Cull [_Cull]

			HLSLPROGRAM
			#pragma exclude_renderers gles gles3 glcore
			#pragma target 2.0

			#pragma multi_compile_instancing
			#pragma multi_compile DEPTH_ONLY_PASS

			#pragma vertex ShadowDepthPassVertex
			#pragma fragment ScenePickingFragment

			float4 _SelectionID;

			half4 ScenePickingFragment(Varyings input) : SV_Target
			{
				ShadowDepthPassFragment(input);
				return _SelectionID;
			}

			ENDHLSL
		}
	}

	FallBack "Hidden/InternalErrorShader"
	CustomEditor "ToonyColorsPro.ShaderGenerator.MaterialInspector_SG2"
}

/* TCP_DATA u config(ver:"2.9.21";unity:"6000.3.4f1";tmplt:"SG2_Template_URP";features:list["UNITY_5_4","UNITY_5_5","UNITY_5_6","UNITY_2017_1","UNITY_2018_1","UNITY_2018_2","UNITY_2018_3","UNITY_2019_1","UNITY_2019_2","UNITY_2019_3","UNITY_2019_4","UNITY_2020_1","UNITY_2021_1","UNITY_2021_2","UNITY_2022_2","UNITY_6000_2","UNITY_6000_1","UNITY_6000_0","ENABLE_DEPTH_NORMALS_PASS","ENABLE_FORWARD_PLUS","BUMP","BUMP_SCALE","BUMP_SHADER_FEATURE","VERTEX_SIN_WAVES","DEPTH_BUFFER_COLOR","DEPTH_BUFFER_FOAM","FOAM_ANIM","SMOOTH_FOAM","DEPTH_BUFFER_ALPHA","SKETCH_PROGRESSIVE","SKETCH_PROGRESSIVE_SMOOTH","SKETCH_SHADER_FEATURE","OUTLINE","OUTLINE_URP_FEATURE","AUTO_TRANSPARENT_BLENDING","ALPHA_TESTING","TEMPLATE_LWRP"];flags:list[];flags_extra:dict[];keywords:dict[RENDER_TYPE="TransparentCutout",RampTextureDrawer="[TCP2Gradient]",RampTextureLabel="Ramp Texture",SHADER_TARGET="3.0"];shaderProperties:list[,,,,,,,,,,,sp(name:"Progressive Sketch Texture";imps:list[imp_mp_texture(uto:True;tov:"";tov_lbl:"";gto:False;sbt:False;scr:False;scv:"";scv_lbl:"";gsc:False;roff:False;goff:False;sin_anm:False;sin_anmv:"";sin_anmv_lbl:"";gsin:False;notile:False;triplanar_local:False;def:"black";locked_uv:False;uv:6;cc:4;chan:"RGBA";mip:-1;mipprop:False;ssuv_vert:False;ssuv_obj:False;uv_type:Triplanar;uv_chan:"XZ";tpln_scale:1;uv_shaderproperty:__NULL__;uv_cmp:__NULL__;sep_sampler:__NULL__;prop:"_ProgressiveSketchTexture";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"395314d5-5ee5-4efe-b37c-f1ab4ef2393b";op:Multiply;lbl:"Progressive Texture";gpu_inst:False;dots_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];layer_blend:dict[];custom_blend:dict[];clones:dict[];isClone:False)];customTextures:list[];codeInjection:codeInjection(injectedFiles:list[];mark:False);matLayers:list[]) */
/* TCP_HASH cfff50bbc8c0fedbea7f19f4bd729201 */
