using UnityEngine;

namespace handtracking
{
    public class HandsShaderDisplacement : MonoBehaviour
    {
        private static readonly int FingerPositions = Shader.PropertyToID("_FingerPositions");
        private static readonly int FingerMaxDist   = Shader.PropertyToID("_FingerMaxDist");
        private static readonly int FingerStrength  = Shader.PropertyToID("_FingerStrength");
        private static readonly int FingerFalloff   = Shader.PropertyToID("_FingerFalloff");

        [SerializeField] private HandTracker handTracker;
        [SerializeField] private float maxDistance = 0.3f;
        [SerializeField] private float strength    = 0.15f;
        [SerializeField] private float falloff     = 2.0f;

        private readonly Vector4[] _handPositions = new Vector4[2];

        private void Update()
        {
            for (var i = 0; i < 2; i++)
            {
                Vector3 pos = handTracker.HandPositions[i];
                _handPositions[i] = new Vector4(pos.x, pos.y, pos.z, 0.0f);
            }

            Shader.SetGlobalVectorArray(FingerPositions, _handPositions);
            Shader.SetGlobalFloat(FingerMaxDist,  maxDistance);
            Shader.SetGlobalFloat(FingerStrength, strength);
            Shader.SetGlobalFloat(FingerFalloff,  falloff);
        }
    }
}