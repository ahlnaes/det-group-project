using UnityEngine;
using Oculus.Interaction.Input;

namespace handtracking
{
    public class HandTracker : MonoBehaviour
    {
        [Header("Hands")]
        [SerializeField] private Hand leftHand;
        [SerializeField] private Hand rightHand;

        public Vector3[] HandPositions { get; private set; } = new Vector3[2];
        public bool IsTracking { get; private set; }

        private void Update()
        {
            IsTracking = false;
            CollectHand(leftHand,  0);
            CollectHand(rightHand, 1);
        }

        void CollectHand(Hand hand, int index)
        {
            // isTrackedDataValid is false when hand is not visible or tracking is lost
            if (hand == null || !hand.IsTrackedDataValid)
            {
                HandPositions[index] = new Vector3(0, -999, 0); // if the hand isn't tracked the positions are 999 under the scene so they don't disturb
                return;
            }

            // WristRoot is the palm/wrist center — good enough approximation for influence origin
            hand.GetJointPose(HandJointId.HandWristRoot, out Pose pose);
            HandPositions[index] = pose.position;
            IsTracking = true;
        }
    }
}