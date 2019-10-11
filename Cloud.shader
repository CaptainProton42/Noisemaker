shader_type spatial;

render_mode skip_vertex_transform, unshaded;

/* Coordinates of the cloud box boundaries. */
uniform vec3 bMin;
uniform vec3 bMax;

/* Cloud parameters. */
uniform vec3 windDirection = vec3(1.0f, 0.0f, 0.0f);
uniform float offset : hint_range(0.0, 1.0f);
uniform float cloudScale : hint_range(0.1, 100.0);
uniform int numSteps : hint_range(1, 50);
uniform int numStepsLight : hint_range(1, 50);
uniform float lightAbsorptionTowardsSun : hint_range(0.0, 10.0);
uniform float cloudAbsorption : hint_range(0.0, 10.0);

/* World information. */
uniform vec3 sunDirection; // Direction of the sun in world coordinates.
uniform vec4 sunColor : hint_color; // Color of the sun.

/* Noise sampler. (Currently broken.) */
uniform sampler3D volume;

/* Set the quad to always be in front of the camera. */
void vertex()
{
	PROJECTION_MATRIX = mat4(1.0);
}

/* Density sampler. */
float sampleDensity(vec3 position)
{
	float density = 1.0 - texture(volume, mod(position.xyz / cloudScale + windDirection*offset, 1.0)).r;
	return density;
}

/* Box intersector. */
vec2 rayBoxDst(vec3 boundsMin, vec3 boundsMax, vec3 rayOrigin, vec3 rayDir)
{
	vec3 t0 = (boundsMin - rayOrigin) / rayDir;
	vec3 t1 = (boundsMax - rayOrigin) / rayDir;
	vec3 tmin = min(t0, t1);
	vec3 tmax = max(t0, t1);
	
	float dstA = max(max(tmin.x, tmin.y), tmin.z);
	float dstB = min(tmax.x, min(tmax.y, tmax.z));
	
	float dstToBox = max(0, dstA);
	float dstInBox = max(0, dstB - dstToBox);

	return vec2(dstToBox, dstInBox);
}

/* Calculate how much sunlight reaches the given position in the cloud. */
float lightmarch(vec3 position)
{
	float dstInBox = rayBoxDst(bMin, bMax, position, normalize(sunDirection)).y;
	
	float stepSize = dstInBox / float(numStepsLight);
	float totalDensity = 0.0f;
	
	for (int step = 0; step < numStepsLight; ++step)
	{
		position += sunDirection * stepSize;
		totalDensity += max(0, sampleDensity(position) * stepSize);
	}
	float transmittance = exp(-totalDensity * lightAbsorptionTowardsSun);
	return transmittance;
}

// Raymarching shader.
void fragment()
{
	vec3 rayOrigin = (CAMERA_MATRIX * vec4(0.0f, 0.0f, 0.0f, 1.0f)).xyz;
	vec3 rayDir = normalize((CAMERA_MATRIX * INV_PROJECTION_MATRIX * vec4(2.0f*SCREEN_UV - 1.0f, 1.0f,1.0f)).xyz);
	
	vec2 rayBoxInfo = rayBoxDst(bMin, bMax, rayOrigin, rayDir);
	float dstToBox = rayBoxInfo.x;
	float dstInBox = rayBoxInfo.y;
	
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = length(view.xyz); // Eye distance.
	
	float dstTravelled = 0.0f;
	float lightEnergy = 0.0f;
	float transmittance = 1.0f;
	float maxDst = min(linear_depth - dstToBox, dstInBox);
	
	/* Putting this here improves visual quality dramatically
	even for low step numbers while keeping computational complexity
	consistent. */
	float stepSize = maxDst / float(numSteps);

	while (dstTravelled < maxDst)
	{
		vec3 rayPos = rayOrigin + rayDir * (dstToBox + dstTravelled);
		float density = sampleDensity(rayPos);
		if (density > 0.0f)
		{
			float lightTransmittance = lightmarch(rayPos);
			lightEnergy += density * stepSize * transmittance * lightTransmittance;
			transmittance *= exp(-density * stepSize * cloudAbsorption);
			
			if (transmittance < 0.01) break;
		}
		dstTravelled += stepSize;
	}

	vec3 backgroundCol = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	vec3 cloudCol = lightEnergy * sunColor.rgb;
	ALBEDO = backgroundCol * transmittance + cloudCol;
}