using UnityEngine;

namespace shader
{
    public class RoomGeometryGlobals : MonoBehaviour
    {
        [Header("Scene References")]
        [SerializeField] private Renderer pedestalRenderer;

        [Header("Room Geometry (world units)")]
        [SerializeField] private float wallRadius = 11.47f;
        [SerializeField] private float wallHeight = 6.03f;

        [Header("Lines")]
        [SerializeField] private float lineFrequency = 10.0f;

        private static readonly int PropWallRadius     = Shader.PropertyToID("_WallRadius");
        private static readonly int PropWallHeight     = Shader.PropertyToID("_WallHeight");
        private static readonly int PropPedestalBaseY  = Shader.PropertyToID("_PedestalBaseY");
        private static readonly int PropPedestalHeight = Shader.PropertyToID("_PedestalHeight");
        private static readonly int PropPedestalRadius = Shader.PropertyToID("_PedestalRadius");
        private static readonly int PropLineFrequency  = Shader.PropertyToID("_LineFrequency");

        private void OnValidate() => Push();
        private void Awake()      => Push();
        private void Start()      => Push();

        private void Push()
        {
            if (pedestalRenderer == null) return;

            Bounds pedBounds = pedestalRenderer.bounds;

            Shader.SetGlobalFloat(PropWallRadius,     wallRadius);
            Shader.SetGlobalFloat(PropWallHeight,     wallHeight);
            Shader.SetGlobalFloat(PropPedestalBaseY,  pedBounds.min.y);
            Shader.SetGlobalFloat(PropPedestalHeight, pedBounds.size.y);
            Shader.SetGlobalFloat(PropPedestalRadius, pedBounds.extents.x);
            Shader.SetGlobalFloat(PropLineFrequency,  lineFrequency);
        }
    }
}