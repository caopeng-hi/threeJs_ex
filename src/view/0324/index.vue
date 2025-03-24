<template>
  <div ref="contentRef" class="content"></div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import * as THREE from "three";
const contentRef = ref(null);
onMounted(() => {});
</script>

<style lang="scss" scoped></style>
