@react.component
let make = React.memo((~size) =>
  <svg
    version="1.1"
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 56 56"
    height={size->Int.toString}>
    <g fill="#3c3c3c">
      <path
        d="M 45.138 10.2426 C 40.482 5.5786 34.286 3.007 27.6736 3.0006 C 14.0804 3.0006 3.0116 14.0578 3 27.6506 c -0.0064 6.5916 2.5548 12.7904 7.21 17.456 c 4.6568 4.6628 10.8284 7.2436 17.4196 7.2436 h 0.0572 v -0.0024 c 13.4956 0 24.654 -11.0596 24.664 -24.6516 c 0.0064 -6.5912 -2.5584 -12.7892 -7.2128 -17.4536 z m -16.368 30.47 c -0.2836 0.2864 -0.68 0.4504 -1.0872 0.4504 c -0.4088 -0.0008 -0.8064 -0.1656 -1.0932 -0.456 c -0.2848 -0.2824 -0.4484 -0.6792 -0.448 -1.0876 c 0.0008 -0.4072 0.1664 -0.8064 0.4532 -1.0924 c 0.2856 -0.2848 0.7064 -0.4488 1.092 -0.4488 c 0.406 0 0.8028 0.1648 1.086 0.4504 c 0.2896 0.292 0.4556 0.6916 0.4548 1.0932 c -0.0004 0.4032 -0.1672 0.8004 -0.4576 1.0908 z m 0.7424 -9.4452 a 0.3854 0.3854 90 0 0 -0.3024 0.3752 l -0.002 1.812 c -0.0008 0.8488 -0.6916 1.5408 -1.5436 1.5408 c -0.8512 -0.0008 -1.5412 -0.694 -1.5404 -1.5436 l 0.0036 -3.4964 c 0.0008 -0.8484 0.6916 -1.508 1.5416 -1.508 h 0.0068 c 2.9488 0 5.35 -2.432 5.3532 -5.3808 c 0.0012 -1.4288 -0.5536 -2.7884 -1.564 -3.8024 c -1.014 -1.0132 -2.3568 -1.5788 -3.7884 -1.5804 c -2.9492 0 -5.3512 2.3956 -5.3544 5.3464 c -0.0008 0.8492 -0.6924 1.538 -1.544 1.538 a 1.529 1.529 90 0 1 -1.09 -0.4544 c -0.2916 -0.2912 -0.4508 -0.6788 -0.4504 -1.0904 c 0.0044 -4.6492 3.7896 -8.4324 8.4448 -8.4324 c 4.6532 0.0048 8.4344 3.7936 8.43 8.446 c -0.0032 3.9172 -2.778 7.3788 -6.6004 8.2304 z"
      />
    </g>
  </svg>
)